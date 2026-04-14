---
layout: post
title: AI 驱动的求职工具链：从 JD 分析到自动投递
categories: [ai, tools]
description: 用 RAG + LLM 构建精准的求职 Gap 分析和自动投递系统
keywords: AI, 求职, RAG, ChromaDB, Claude API, 简历优化, BOSS直聘
---

> 求职不应该是大海捞针，而应该是精准匹配。

## 痛点

求职过程中有两个核心痛点：

1. **不知道差距在哪** — 看了一堆 JD，觉得自己都能做，投了简历却石沉大海。到底哪些技能是必须的？简历哪里需要调整？
2. **重复劳动太多** — 在 BOSS 直聘上一个个点开聊，每天的沟通额度很快用完，效率极低。

我用 AI 构建了一套工具链来解决这两个问题。

## 工具一：AI Job Matcher — 精准 Gap 分析

[ai-job-matcher](https://github.com/bob798/ai-job-matcher) 不是通用的简历美化工具，而是基于真实 JD 数据的精准 Gap 分析系统。

### 工作流程

```
JD 采集（手动粘贴 / Jina Reader 批量抓取）
    │
    ▼
ChromaDB 向量化（all-MiniLM-L6-v2 本地 embedding）
    │
    ▼
多角度 RAG 检索（5 个视角覆盖 JD 全维度）
    │
    ▼
Claude API Gap 分析
    │
    ▼
Markdown 报告输出
├── 匹配优势
├── 技能缺口
├── ATS 关键词
├── 3 条改写示例（改写前/后对比）
└── BOSS 直聘打招呼话术
```

### 为什么用 RAG 而不是直接丢给 LLM

直接把简历和 JD 丢给 ChatGPT 也能分析，但有两个问题：

- **单次分析视角单一**：LLM 倾向于给出笼统的评价，容易遗漏细节
- **无法跨 JD 对比**：当你有 10+ 个目标岗位时，需要知道哪些技能是行业共识、哪些是个别要求

RAG 的优势在于：先把所有 JD 向量化入库，然后从技术栈、职责描述、资质要求等多个角度检索，再交给 LLM 做综合分析。这样的分析更全面、更有数据支撑。

### 技术选型

| 组件 | 选型 | 理由 |
|------|------|------|
| 向量数据库 | ChromaDB | 本地运行，持久化，零成本 |
| Embedding | all-MiniLM-L6-v2 | ChromaDB 内置，无需 OpenAI |
| LLM | Claude API | Gap 分析质量高 |
| JD 抓取 | Jina Reader API | 合规、免费 |

## 工具二：Auto Resume Bot — 自动投递

Gap 分析告诉你简历怎么改，改好之后需要高效投递。

[auto-resume-bot](https://github.com/bob798/auto-resume-bot) 基于 Puppeteer 实现 BOSS 直聘自动化：

- **自动开聊**：按求职偏好自动匹配并开聊推荐职位
- **智能筛选**：对工作地、薪资、经验、职位描述、BOSS 活跃度等多维度匹配
- **已读不回复聊**：自动跟进已读不回的 BOSS，提高沟通转化率
- **异常处理**：当天额度用完自动暂停，第二天继续

## 完整求职工作流

把两个工具串起来，形成闭环：

```
第一步：收集目标 JD
   │  Jina Reader 批量抓取 + 手动补充
   ▼
第二步：Gap 分析
   │  ai-job-matcher 输出精准报告
   ▼
第三步：针对性优化简历
   │  根据报告中的改写建议调整
   ▼
第四步：自动投递
   │  auto-resume-bot 批量开聊
   ▼
第五步：复盘迭代
   │  根据面试反馈回到第二步
```

## 实际效果

用这套工具链之后：

- 从"觉得自己都能做"变成"清楚知道差距在哪"
- 简历改写有了数据支撑，不再凭感觉
- 投递效率大幅提升，不再一个个手动点

## 开源

- Gap 分析：[github.com/bob798/ai-job-matcher](https://github.com/bob798/ai-job-matcher)
- 自动投递：[github.com/bob798/auto-resume-bot](https://github.com/bob798/auto-resume-bot)
