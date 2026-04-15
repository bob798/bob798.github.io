---
title: "模拟面试官开发复盘"
date: 2026-03-29
tags: ["ai-handbook", "rag"]
---

# 模拟面试官开发复盘

> 记录从零搭建「文字版 AI 面试官」过程中遇到的关键问题、设计决策和优化经验。
> 涵盖：Prompt 设计、LLM 能力边界、解析策略、多轮对话架构。

---

## 一、HTML 内容解析策略

### 问题

手写 `html.parser` 方案（`_TextExtractor`）只做了标签过滤，提取出的是纯文本流，**标题与正文完全脱钩**：

```
向量检索中，余弦相似度的计算公式...   ← 无法知道这段属于哪个章节
```

导致检索时模型无法判断这段内容的语义位置，相关性偏低。

### 解法：HTMLHeaderTextSplitter + 面包屑注入

引入 LangChain `HTMLHeaderTextSplitter`，按 h1/h2/h3 层级切块，标题自动注入每个 chunk：

```
[向量检索 > 余弦相似度]
向量检索中，余弦相似度的计算公式...
```

再用 `RecursiveCharacterTextSplitter`（chunk_size=500, overlap=50）二次切割过长块。

**效果对比**：

| | 手写 parser | HTMLHeaderTextSplitter |
|---|---|---|
| 标题上下文 | 无 | h1>h2>h3 面包屑 |
| chunk 大小控制 | 按标点切，碎片多 | 500字+50字overlap |
| 跨 chunk 断裂 | 常见 | overlap 减少断裂 |
| 依赖 | 标准库 | langchain-text-splitters + bs4 |

### 经验

> HTML 文档的层级结构本身就是语义信息，丢弃标题 = 丢弃上下文。
> 向量化时把标题面包屑注入 chunk，等于给 embedding 加了"定位坐标"。

---

## 二、多轮对话的状态管理

### 问题

最初打算复用 v9 的 `agentic_loop()`，但发现它每次调用都重置 `messages = []`：

```python
def agentic_loop(user_input):
    messages = []        # ← 每次都清空，面试官完全失忆
    messages.append({"role": "user", "content": user_input})
    ...
```

多轮面试下，面试官不记得上一题问了什么，候选人如何回答，无法追问也无法评分。

### 解法：messages 作为外部状态

新增 `interview_turn(user_content, messages)` — `messages` 由外部维护，跨轮传递：

```python
def interview_turn(user_content: str, messages: list) -> tuple[str, list]:
    messages.append({"role": "user", "content": user_content})
    for _ in range(6):
        resp = client.chat.completions.create(
            messages=messages,   # ← 每次携带完整历史
            tools=[SEARCH_TOOL_DEF],
            ...
        )
        ...
    return response, messages    # ← 返回更新后的 messages

# 主循环：messages 跨轮保留
messages = [{"role": "system", "content": SYSTEM_PROMPT}]
while True:
    answer = input()
    response, messages = interview_turn(answer, messages)
```

### 经验

> 单轮问答和多轮对话是两种不同的 LLM 使用模式。
> 单轮：每次独立调用，messages 可以重置。
> 多轮：messages 是"记忆"，必须作为状态在轮次间传递，且 system prompt 只加一次。

---

## 三、Prompt 设计：防止 LLM 泄题

### 问题

面试官在提问前，把 `search_kb` 检索结果当"背景介绍"说出来：

```
面试官：根据知识库，RAG 主要解决了大模型的两个核心痛点：
        一是知识截止日期…二是私有领域知识缺失…
        那么，RAG 是如何解决这两个痛点的？
```

等于把答案说了一遍再问问题。

**根本原因**：Prompt 只说"用知识库出题"，没有明确区分"内部使用"和"对外输出"。
LLM 默认会把检索到的内容融入回答，这是它的正常行为。

### 解法：明确区分工具的使用边界

```
【核心原则：绝对禁止泄题】
- 提问时只说问题本身，禁止透露答案、参考答案或任何提示
- search_kb 检索结果只能用于内部核实，不能说给候选人听
- 不要以"根据知识库…"开头解释背景，直接问问题
```

### 经验

> LLM 的工具调用结果默认会被融入输出，这是"有帮助"的正常行为。
> 如果需要工具结果"只用于推理，不用于输出"，必须在 Prompt 中**显式声明**这个边界。
> 面试官场景中：检索 = 内部核实，输出 = 只有问题本身。

---

## 四、出题流程设计：指令模式

### 问题

如何让面试官按结构化 QA 数据集出题，而不是自由发挥？

直接在 system prompt 里列出题目不可行（token 消耗大，且面试官可能跳题）。

### 解法：`[下一题]` 指令注入

代码控制出题权，在每次用户回答后，将下一题附加到消息末尾：

```python
# 代码侧：选题 + 拼接指令
next_q_hint = f"\n\n[下一题] {current_qa['question']}"
user_msg = answer + next_q_hint

# System prompt 侧：定义指令语义
收到 [下一题] 指令：只做一件事——用自然语气把题目问出来，不加背景说明
```

**出题来源两路**：

| 阶段 | 指令 | 面试官行为 | 评估方式 |
|---|---|---|---|
| QA 题库未耗尽 | `[下一题] <question>` | 换语气提问 | key_points 结构化打分 |
| QA 题库耗尽 | `[继续出题]` | search_kb 检索后自主出题 | 跳过结构化评估 |

### 经验

> "让 LLM 从数据集里选题"不如"代码选题后告诉 LLM 来问"可靠。
> 指令模式（`[下一题]`）把控制权留在代码侧，LLM 只负责自然语言表达。
> System prompt 中对指令的定义要简洁明确，避免 LLM 过度发挥。

---

## 五、评估与对话的隔离

### 设计

`evaluate_answer()` 是完全独立的 LLM 调用，**不加入 `messages` 历史**：

```python
def evaluate_answer(qa, user_answer):
    resp = client.chat.completions.create(
        messages=[{"role": "user", "content": eval_prompt}],  # 独立的单次调用
        temperature=0,
    )
    return parse_json(resp)
```

### 原因

1. **防止评分标准泄漏**：如果把 key_points 评估结果追加到 messages，面试官后续回复可能会暗示候选人"你漏了 k=60 这个点"
2. **职责分离**：面试官负责追问引导，评估器负责打分，互不干扰
3. **可替换性**：评估逻辑可以独立升级（换模型、换 prompt），不影响面试对话

### 经验

> 一个 LLM 应用中，不同职责的 LLM 调用应该隔离上下文。
> 共享 messages 会导致角色污染：面试官看到了评分标准，评估器看到了追问历史。

---

## 六、Tool Calling 解析的兼容性问题

### 问题

部分 provider（如 siliconflow）对 Tool Calling 的 `arguments` 字段会**二次序列化**：

```python
tc.function.arguments = '"{\"query\": \"RRF原理\"}"'  # 字符串套字符串
args = json.loads(tc.function.arguments)
# args = '{"query": "RRF原理"}'  ← 还是字符串，不是 dict
args.get("query")  # AttributeError: 'str' object has no attribute 'get'
```

### 解法

```python
args = json.loads(tc.function.arguments)
if isinstance(args, str):     # 兼容二次序列化
    args = json.loads(args)
```

### 经验

> OpenAI 规范的实现质量因 provider 而异，Tool Calling 是高频差异点。
> 防御性解析：对 LLM 输出的结构化数据，始终做类型检查再使用。
> 常见的 provider 差异：arguments 二次序列化、tool_call_id 格式、流式 tool call 分片。

---

## 七、KB 版本管理：自动重建检测

### 问题

改变分块策略后，旧的 ChromaDB 数据仍在，不会自动重建，导致新旧策略混用。

### 解法

在 collection metadata 存储策略版本号：

```python
KB_VERSION = "v2_header_split"

collection = client.get_or_create_collection(
    metadata={"kb_version": KB_VERSION, ...}
)

# 加载时检查版本
if collection.metadata.get("kb_version") != KB_VERSION:
    shutil.rmtree(DB_PATH)   # 删除旧库
    collection = rebuild()   # 重建
```

### 经验

> 向量数据库是有状态的缓存，分块策略/embedding 模型变化后必须重建。
> 版本号是最简单的失效检测机制，比对比文件哈希要轻量得多。

---

## 八、LLM 能力边界总结

| 场景 | LLM 表现 | 应对策略 |
|---|---|---|
| 工具结果融入输出 | 默认行为，无法自动抑制 | Prompt 显式声明"工具结果仅内部使用" |
| 多轮记忆 | 无内置记忆，每次调用独立 | 外部维护 messages 状态跨轮传递 |
| 按指令执行 | 小模型（<32B）指令遵循不稳定 | 用代码控制关键决策，LLM 只负责表达 |
| 结构化输出 | JSON 格式不稳定，可能带 ``` 包裹 | 用 `if "```" in content` 提取，加 try/except |
| Tool Calling | provider 实现差异大 | 防御性解析，做类型检查 |

---

## 参考文件

- `rag/code/11_模拟面试官.py` — 主程序
- `rag/code/interview_qa.json` — 结构化题库（22 道，含 key_points）
- `rag/code/chromadb-inspect.md` — ChromaDB 调试指南
- `rag/code/logs/` — 每次面试的 JSONL 记录（gitignore）
