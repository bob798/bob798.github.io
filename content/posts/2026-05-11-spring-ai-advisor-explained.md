---
title: "Spring AI Advisor：LLM 调用链上的 AOP"
date: 2026-05-11
description: "从 Filter/HandlerInterceptor/@Around 视角理解 Spring AI Advisor，覆盖核心接口、内置 Advisor 清单、自定义审计场景与 ToolCallAdvisor 的取舍"
tags: ["spring-ai", "llm", "java", "aop", "advisor"]
draft: false
---

> 适用版本：Spring AI 2.0.0-M4
> 关键词：Advisor / ChatClient / ToolCallAdvisor / ChatMemoryAdvisor

## 一句话理解

**Advisor 是 Spring AI 的拦截器链**。它围绕 `ChatClient.prompt().call()` 织入一圈钩子，对发往模型的请求（`ChatClientRequest`）和返回的响应（`ChatClientResponse`）做加工。

把它和你已经熟悉的概念对齐：

| 你熟悉的 | 对应 Spring AI |
|---|---|
| Servlet `Filter` | `CallAdvisor` |
| Spring MVC `HandlerInterceptor` | `BaseAdvisor` |
| Spring AOP `@Around` | Advisor 的 before/after 钩子 |
| Express/Koa middleware | Advisor chain |

所以它不是"高级特性"，而是 LLM 调用链的标准切面机制。

## 核心接口（M4 版本）

```java
// 顶层标记
interface Advisor extends Ordered {
    String getName();
    int getOrder();   // 越小越靠外
}

// 同步路径：完全控制是否继续往里走
interface CallAdvisor extends Advisor {
    ChatClientResponse adviseCall(ChatClientRequest req, CallAdvisorChain chain);
    //                                                   ↑ 调 chain.nextCall(req) 才进入下一站
}

// 流式路径
interface StreamAdvisor extends Advisor {
    Flux<ChatClientResponse> adviseStream(ChatClientRequest req, StreamAdvisorChain chain);
}

// 简化版：只关心改请求/改响应，不需要决定流转
interface BaseAdvisor extends CallAdvisor, StreamAdvisor {
    ChatClientRequest  before(ChatClientRequest  req, AdvisorChain chain);
    ChatClientResponse after(ChatClientResponse resp, AdvisorChain chain);
}
```

**调用模型本身**也是链上最后一个 advisor（内置的 `ChatModelCallAdvisor`），所以整个调用链长这样：

```
[你的 Advisor 1, 你的 Advisor 2, ..., ChatModelCallAdvisor]
```

外层 advisor 的 `before` 先跑、`after` 后跑 —— 跟 `@Around` 完全一致。

## 5 行注册

每次请求注册：

```java
chatClient.prompt()
    .user("查询A栋本月能耗")
    .advisors(new MyAuditAdvisor(),                          // 自定义
              MessageChatMemoryAdvisor.builder(memory).build(),  // 内置：记忆
              new SimpleLoggerAdvisor())                     // 内置：日志
    .call()
    .content();
```

全局注册（推荐）：

```java
@Bean
ChatClient chatClient(ChatModel model, ChatMemory memory) {
    return ChatClient.builder(model)
        .defaultAdvisors(
            new MyAuditAdvisor(),
            MessageChatMemoryAdvisor.builder(memory).build()
        )
        .build();
}
```

## M4 自带的 Advisor 清单

| Advisor | 用途 |
|---|---|
| `ToolCallAdvisor` | **多轮工具调用循环**。等价于自己写的 while 循环 + maxIterations 控制 |
| `MessageChatMemoryAdvisor` | 把 `ChatMemory` 里的历史消息以 message 形式拼回 prompt |
| `PromptChatMemoryAdvisor` | 把历史以 system prompt 形式拼回（适合不支持多轮的模型） |
| `QuestionAnswerAdvisor` | RAG —— 检索向量库，把 top-K 文档拼到 prompt 里 |
| `SafeGuardAdvisor` | 敏感词/越权拦截 |
| `SimpleLoggerAdvisor` | 打 request/response 日志 |
| `ChatModelCallAdvisor` | 链尾：真正调模型。你不用手加 |

## 自己写一个 —— 审计场景

假设要给每次 LLM 调用打租户/用户审计日志（多租户 SaaS 场景）：

```java
@Component
public class TenantAuditAdvisor implements BaseAdvisor {

    @Override public String getName()  { return "tenant-audit"; }
    @Override public int    getOrder() { return 1000; }   // 在 ToolCallAdvisor 外圈

    @Override
    public ChatClientRequest before(ChatClientRequest req, AdvisorChain chain) {
        log.info("[AI] tenant={} user={} prompt-len={}",
                TenantContext.getTenantId(),
                SecurityHolder.userId(),
                req.prompt().getContents().length());
        return req;   // 不改请求时原样返回
    }

    @Override
    public ChatClientResponse after(ChatClientResponse resp, AdvisorChain chain) {
        ChatResponse cr = resp.chatResponse();
        if (cr != null && cr.getMetadata() != null) {
            log.info("[AI] usage={} finishReason={}",
                    cr.getMetadata().getUsage(),
                    cr.getResult().getMetadata().getFinishReason());
        }
        return resp;
    }
}
```

把它放到全局 `defaultAdvisors`，所有 chat 调用自动带上审计 —— 不侵入业务代码。

## 调用顺序图

```
ChatClient.prompt().call()
   │
   ├─ Order=0    SimpleLoggerAdvisor.before()       ─┐
   ├─ Order=100  MetricsAdvisor.before()             │ Request 加工
   ├─ Order=200  ChatMemoryAdvisor.before()          │ 外圈先 before
   ├─ Order=300  RAGAdvisor.before()                ─┘
   │
   ├─ ChatModelCallAdvisor.adviseCall()      ← 调 LLM + 工具循环
   │
   ├─ Order=300  RAGAdvisor.after()                 ─┐
   ├─ Order=200  ChatMemoryAdvisor.after()           │ Response 加工
   ├─ Order=100  MetricsAdvisor.after()              │ 外圈后 after
   └─ Order=0    SimpleLoggerAdvisor.after()        ─┘
```

记住：`order` 数字越小越靠外。

## 什么时候用 Advisor，什么时候不用

**用**：

- 横切关注点：日志、metrics、审计、限流、敏感词
- 数据增强：RAG 检索拼接、上下文记忆、租户隔离
- 替换内置循环：工具调用控制（`ToolCallAdvisor`）

**不用**：

- 业务逻辑（应该在 Service 里）
- 简单的请求改造（直接构造 `Prompt` 就行）
- 流程控制超出"前置/后置"语义（这时该写自定义 ChatClient）

## 一个实际权衡：何时不用 ToolCallAdvisor

如果你需要：

- 自定义 `maxRounds` 超过/降级行为
- 每轮 LLM 响应的细粒度日志
- 总耗时 wall-clock 超时（不只是每轮 HTTP 超时）
- 双重降级（summary 仍调工具时硬退）

那么手写 while 循环可能比 `ToolCallAdvisor` 更可控。生产化项目里通常先用手写循环原型化，**等行为稳定后再迁移到 Advisor**。

## 迁移路径示意

PoC：手写工具循环
```java
while (response.hasToolCalls() && round++ < maxRounds) {
    var result = toolCallingManager.executeToolCalls(prompt, response);
    prompt = new Prompt(result.conversationHistory(), prompt.getOptions());
    response = chatModel.call(prompt);
}
```

升级到 Advisor：
```java
ChatClient.builder(chatModel)
    .defaultAdvisors(
        new TimeoutAdvisor(Duration.ofSeconds(90)),     // 外圈：总超时
        new MetricsAdvisor(),                            // 中圈：指标
        ToolCallAdvisor.builder()                        // 内圈：工具循环
            .maxIterations(5)
            .build()
    )
    .build();
```

Service 层从 70 行 + CompletableFuture 缩成 3 行：
```java
String reply = chatClient.prompt().user(query).call().content();
```

## 小结

Advisor = LLM 链上的 AOP。掌握它，等于掌握了 Spring AI 的扩展点。先用内置的（`ToolCallAdvisor` / `MessageChatMemoryAdvisor` / `QuestionAnswerAdvisor`）跑通，再用自定义 `BaseAdvisor` 织入横切逻辑，最后只把无法通过钩子表达的复杂控制流落到 Service。

这套切面机制把 Spring AI 的扩展点边界划得很清楚，是把 LLM 应用工程化的关键一步。
