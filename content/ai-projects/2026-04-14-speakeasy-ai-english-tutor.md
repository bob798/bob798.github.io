---
title: "Speakeasy：用 AI 做你的英语私教"
date: 2026-04-14
description: "一个越聊越懂你的 AI 英语私教，产品理念与技术实现"
tags: ["ai", "product"]
---
> 学英语的人不缺资源，缺的是一个真正认识你的练习对象。

## 为什么做 Speakeasy

背单词、刷题、上课——练完就忘，下次重头再来。每个英语 App 对你一无所知：不知道你做什么工作，不记得你上次说过什么，不知道你哪里弱、哪里已经很好。

通用 AI 能聊，但每次对话结束，一切清零。它不积累，不进化，不认识你。

**Speakeasy 的核心切入点：一个真正在积累对你的了解的英语私教。**

## Alex 是谁

Alex 是 Speakeasy 中的 AI 私教。你们聊真实生活里的事——今天的会议、遇到的麻烦、周末去了哪里。Alex 持续积累对你的认知：你是做什么的、你哪里容易出错、你上周发生了什么。

Alex 通过两种方式带你进步：

### 隐式引导（你感知不到，但在发生）

对话过程中，Alex 自然地在回复里植入你需要强化的表达。你以为在聊天，Alex 知道你在进步。

```
你说：Yesterday I go to a meeting with my boss...

Alex：Oh that sounds tough — how did the meeting go?
       Did your boss bring up the budget issue you mentioned last week?
```

Alex 用 "did the meeting go" 自然示范了过去时，同时追问了你上周提过的话题。没有红字标注，没有打断聊天的节奏。

### 显式复盘（对话后，你主动回顾）

每次对话结束，Alex 生成复盘卡片：今天哪里说得地道，哪里有更自然的说法。

## 三层记忆系统

这是 Speakeasy 区别于所有 AI 聊天工具的核心：

```
每次对话结束后：

对话内容
   │
   ├─► grammar_cards    你反复出现的语法习惯
   │   （FSRS 算法调度：科学安排何时在对话中强化）
   │
   ├─► user_facts       你的生活在发生什么
   │   LLM 提取关键事实："用户本周有重要演示"
   │
   └─► user_profile     你是谁
       职业背景 / 英语水平 / 话题偏好 / 学习目标
```

下次对话开始时，三层记忆注入 Alex 的上下文。Alex 知道你的语言习惯、上周发生了什么、你在朝什么方向走。

## FSRS 间隔重复算法

对于你的语法错误，Speakeasy 使用 FSRS（Free Spaced Repetition Scheduler）算法管理复习节奏。不同于传统的死记硬背，FSRS 根据遗忘曲线动态调整：

- 新出现的错误 → 近期对话中高频强化
- 已掌握的模式 → 逐渐拉长间隔
- 反复出错的点 → 加密复习频率

这一切都在自然对话中无感完成。

## 技术架构

| 组件 | 选型 | 理由 |
|------|------|------|
| 后端 | FastAPI (Python) | 异步支持好，AI 生态丰富 |
| LLM | 多模型支持 (Claude / DeepSeek / Doubao) | 通过 OpenRouter 统一代理 |
| 语音输入 | faster-whisper (STT) | 本地部署，延迟低 |
| 语音输出 | edge-tts (TTS) | 免费，音质自然 |
| 数据库 | SQLite | 轻量够用，V1.0 前无需 PostgreSQL |
| 记忆调度 | FSRS | 科学的间隔重复算法 |

## 与直接用 ChatGPT 的区别

| 维度 | ChatGPT | Speakeasy (Alex) |
|------|---------|------------------|
| 记得你说过什么 | 不记得，每次重头 | 记得，会追问上次那件事后来怎样了 |
| 记得你的语法习惯 | 不记得 | 记得，持续在对话中针对性强化 |
| 知道你做什么工作 | 不知道 | 知道，话题和词汇贴合你的职业场景 |
| 随时间进化 | 不会 | 会，越聊越精准 |
| 怎么带你进步 | 靠你自己引导 | 隐式引导 + 显式复盘，双路径同步 |

## 开源

Speakeasy 完全开源，欢迎体验和贡献：[github.com/bob798/speakeasy](https://github.com/bob798/speakeasy)
