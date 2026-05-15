---
title: "如何达到 OpenAI / Anthropic 员工的 AI 认识水平"
date: 2026-05-15
draft: true
description: "从 API 用户到能和顶级 AI 公司员工坐下来聊技术的完整路线：拆 transformer、读 20 篇必读论文、做两个有 eval 的真项目"
tags: ["learning", "ai", "roadmap"]
---

# 如何达到 OpenAI / Anthropic 员工的 AI 认识水平

## 0. 先纠正一个误区

OpenAI / Anthropic 员工的"认知水平"，**70% 你能从外部复制，剩 30% 复制不了**。

那 30% 是：内部模型、内部数据、内部评测集、和顶尖同事每天的脑暴。你再努力也拿不到这部分。

所以学习目标应该重新校准为：

> **能和他们坐下来聊技术不露怯，能读懂他们 80% 的论文和博客，能做出同等品味的工程。**

这是可达成的。

---

## 1. 他们 vs 大多数 API 用户的真正差距

| 他们有 | 大多数 API 用户没有 | 你需要补的 |
|---|---|---|
| 看过几万次模型输出，对失败模式有肌肉记忆 | 只看过自己 prompt 的输出 | 大量动手 + 系统化评测 |
| 不拟人化，从训练数据 / 注意力分布角度思考 | 习惯把模型当人 | 亲手实现一遍 transformer |
| 读过原始论文 | 看二手解读和短视频 | 读 20 篇核心论文 |
| Eval 的工艺感，知道好评测怎么设计 | 看 demo 截图就下结论 | 自己搭一套 eval harness |
| 判断力：分得清研究 hype 和真进展 | 跟着热搜走 | 持续写作 + 形成观点 |

---

## 2. 三阶段路线

### 阶段 1：把 transformer 拆开看一遍（4-6 周）

这是从"API 用户"到"懂模型"的**单一最高 ROI 投资**。不做这步，后面读论文永远隔层纸。

**唯一推荐资源**：Karpathy 的 *Neural Networks: Zero to Hero* YouTube 系列。

- 重点看 *Let's build GPT from scratch*（2 小时）和 *Let's reproduce GPT-2*（4 小时）
- **不要只看，必须跟着敲一遍代码**。看完不敲等于没看。
- 完成标志：你能在白板上画出 attention 的矩阵运算，能解释为什么需要 layer norm 和 residual connection

> 配套：3Blue1Brown 的 transformer 可视化系列，建立直觉。

---

### 阶段 2：读 20 篇必读论文（持续 2-3 个月，穿插进行）

这一份清单**够用一辈子**，别贪多。

#### 基础理解（5 篇）

- *Attention Is All You Need*（2017）
- *GPT-3* paper（2020）—— 看 in-context learning 怎么被发现
- *InstructGPT*（2022）—— RLHF 怎么工作
- *Chinchilla*（2022）—— scaling law 真相
- *Constitutional AI*（Anthropic, 2022）—— Anthropic 的核心方法论

#### Agent 和工具使用（4 篇）

- *ReAct*
- *Toolformer*
- *Reflexion*
- Anthropic 的 *Building Effective Agents* 博客

#### 对齐和可解释性（Anthropic 路径必读，5 篇）

- *transformer-circuits.pub* 上的 *A Mathematical Framework for Transformer Circuits*
- *Toy Models of Superposition*
- *Sleeper Agents*
- *Sycophancy* 系列
- Anthropic 的 *Core Views on AI Safety*

#### 最新进展（6 篇，自己挑）

- 关注 arxiv-sanity、Sebastian Raschka 的 newsletter、Anthropic / OpenAI 的官方博客

#### 读论文方法

- 第一遍：读 abstract + intro + conclusion + 图表（30 分钟）
- 觉得真重要再精读
- **坚持每周精读 1 篇**，写一段 200 字的"我的话复述"
- 发到博客最好（已有 Quartz 站点，正好用）

---

### 阶段 3：做两个有 eval 的真项目（持续 3 个月+）

这是把上面所有知识落地的地方。**没有这步，前两阶段都是纸上谈兵。**

#### 项目 1：一个带完整 eval 的领域 RAG

- 不是又一个"问答 demo"，而是要有：
  - 100+ 条标注评测集
  - 自动评分
  - A/B 不同 chunking / embedding / rerank 策略的结果对比表
- 关键能力：你能说出"我换了 BM25 + 向量混合检索后，准确率从 62% 到 71%，但 P95 延迟从 800ms 到 1.4s"

#### 项目 2：一个有可观测性的 Agent

- 任务自选（代码助手、研究助手、数据分析助手都行）
- 必须有：
  - 每一步 LLM 调用的 trace
  - 失败案例分析
  - 至少 3 种失败模式的 mitigation
- 读完 Anthropic 的 *Building Effective Agents* 再开工

#### 加分项

在 Colab 上微调一个小模型（Qwen 1.5B / Llama 3.2 1B），跑一遍 SFT + DPO 全流程。不用做出 SOTA，做完你对训练就有体感了。

---

## 3. 精选资源表（就这些，别囤）

| 资源 | 类型 | 用途 |
|---|---|---|
| Karpathy *Zero to Hero* | YouTube | 唯一的 transformer 入门 |
| *transformer-circuits.pub* | Anthropic 网站 | 模型内部机制，研究品味的天花板 |
| Anthropic *Building Effective Agents* | 博客 | Agent 工程的当代标准 |
| Sebastian Raschka *Ahead of AI* | Newsletter | 每月一次的论文综述，精准且不水 |
| Simon Willison's blog | 博客 | 工程师视角，handson 案例非常多 |

**不推荐**：

- 吴恩达 short courses（太浅）
- B 站速成课（信息密度低）
- 《大模型应用开发》类的中文书（普遍滞后）

---

## 4. 今天能做的一件事

打开 Karpathy 的 *Let's build GPT from scratch*，**只做一件事**：

跟着写完 bigram model 那一段（前 30 分钟的内容）。在你电脑上跑起来，看到 loss 下降。

不要先看完所有视频。**今晚把这 30 分钟跟着敲完，比接下来一周的任何资源囤积都更有价值。**

---

## 5. 怎么判断真的接近了

不是看完了多少课，而是：

- [ ] 看 Anthropic 新论文，标题和图就能猜个八九不离十
- [ ] 别人问"为什么 LLM 会幻觉"、"context window 大了模型为啥更笨"，你能给三个不同层次的解释（用户层、prompt 层、训练分布层）
- [ ] 博客上有至少 5 篇被 AI 同行转发的技术分析
- [ ] 看到一个 AI 产品 demo，你能立刻判断"这个能做出来 vs 这个吹的"

---

## 6. 进度记录

| 日期 | 阶段 | 完成内容 | 笔记链接 |
|---|---|---|---|
| 2026-05-15 | - | 路线确定 | - |
| | | | |
