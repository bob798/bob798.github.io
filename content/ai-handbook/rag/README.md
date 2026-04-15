---
title: "RAG 实战课程"
date: 2026-03-28
tags: ["ai-handbook", "rag"]
---

# RAG 实战课程

售前转 AI 应用工程师 · 面向学习、实战和后续知识库建设的 RAG 学习仓库

---

## 先看什么

现在 `rag/docs` 已经不是“几篇并列文档”，而是一套带统一入口的知识体系。

推荐从这里开始：

- 统一入口：`rag/docs/index.html`
- 系统学习：`rag/docs/00_课程路线图.html`
- 快速回查：`rag/docs/ai-knowledge-hub.html`
- 做项目：`rag/docs/03_工程方法论手册.html`
- 讲解 / 面试：`rag/docs/rag-5d.html`
- 看全貌：`rag/docs/rag-knowledge-map.html`

如果你是第一次学，不要从“快速回查”开始；先打开 `index.html`，再按任务分流。

---

## 当前结构

### `docs/`：统一入口 + 知识页面

| 文件 | 角色 | 适合什么时候打开 |
|------|------|------------------|
| `index.html` | 统一入口，只负责任务分流 | 第一次进入 docs 时先打开 |
| `00_课程路线图.html` | 学习顺序，只负责“先学什么、后学什么” | 系统学习时打开 |
| `ai-knowledge-hub.html` | 快速回查，只负责术语、参数、问题定位、知识对象 | 已经知道要查什么时打开 |
| `01_概念手册_向量与检索.html` | 概念直觉，只负责 embedding / 向量 / 余弦等底层理解 | 跑 V1 代码前打开 |
| `02_代码讲解_V1V2.html` | 代码数据流，只负责解释 V1 / V2 怎么工作 | 准备运行或复习代码时打开 |
| `03_工程方法论手册.html` | 项目落地，只负责评估、badcase、实验、边界 | 开始做真实项目时打开 |
| `rag-knowledge-map.html` | 系统全貌，只负责模块关系和结构感 | 复习整体链路或做方案讲解时打开 |
| `rag-5d.html` | 横向辨析，只负责对比、场景判断、讲解表达、面试复习 | 要讲清楚 RAG 或做面试准备时打开 |
| `knowledge-updates.html` | 更新日志，只负责记录知识库结构和内容变更 | 想看最近做了什么调整时打开 |

### `code/`：可运行代码

| 文件 | 内容 | 依赖 |
|------|------|------|
| `00_配置提供商_先改这个.py` | 切换模型提供商，配置 API Key | `openai`, `numpy` |
| `01_v1_最小RAG循环.py` | embedding + 余弦检索 + Prompt 注入 + 有无 RAG 对比 | 依赖 `00` |
| `02_v2_文档分块策略.py` | 3 种分块策略对比实验 | 依赖 `00` |
| `03_v3.5_黄金数据集.py` | 7 条手标 Query + Recall@3 + MRR，建立检索基线，输出 `baseline.json` | 依赖 `00` |
| `04_v4_embedding选型.py` | 对比同一 Provider 的不同 Embedding 模型，逐条分析差异，输出 `v4_embedding_result.json` | 依赖 `00`, `baseline.json` |
| `05_v5_混合检索.py` | BM25（纯 Python）+ 向量 + RRF 融合，演示互补性，输出 `v5_hybrid_result.json` | 依赖 `00`, `baseline.json`, `chromadb` |
| `06_v6_reranking.py` | Cross-encoder 两阶段精排（bge-reranker-base），召回 Top-10 → 精排 → Top-3，输出 `v6_reranking_result.json` | 依赖 `00`, `baseline.json`, `sentence-transformers` |
| `07_v7_query变换.py` | Multi-Query + HyDE + Step-back 三种 Query 变换，输出 `v7_query_transform_result.json` | 依赖 `00`, `baseline.json` |
| `08_v8_评估框架.py` | RAGAS 风格 4 维评估（Context Recall/Precision + Faithfulness + Answer Relevancy），含 RAGAS 集成代码，输出 `v8_eval_result.json` | 依赖 `00`, `baseline.json` |
| `09_v9_agentic_rag.py` | Self-RAG + Agentic Retrieval + Multi-hop，基于 Tool Calling 实现，输出 `v9_agentic_result.json` | 依赖 `00` |
| `10_v10_enterprise.py` | 语义缓存 + 请求追踪 + 多租户 Namespace + 增量索引更新，输出 `rag_traces.jsonl` | 依赖 `00`, `chromadb` |

---

## 推荐路径

### 1. 系统学习

```text
docs/index.html
  ↓
docs/00_课程路线图.html
  ↓
docs/01_概念手册_向量与检索.html
  ↓
docs/02_代码讲解_V1V2.html#v1
  ↓
code/01_v1_最小RAG循环.py
  ↓
docs/02_代码讲解_V1V2.html#v2
  ↓
code/02_v2_文档分块策略.py
  ↓
docs/03_工程方法论手册.html
  ↓
code/03_v3.5_黄金数据集.py   # → baseline.json
  ↓
code/04_v4_embedding选型.py   # → v4_embedding_result.json
  ↓
code/05_v5_混合检索.py        # → v5_hybrid_result.json
  ↓
code/06_v6_reranking.py       # → v6_reranking_result.json    ★ 需要 sentence-transformers
  ↓
code/07_v7_query变换.py       # → v7_query_transform_result.json
  ↓
code/08_v8_评估框架.py        # → v8_eval_result.json
  ↓
code/09_v9_agentic_rag.py     # → v9_agentic_result.json
  ↓
code/10_v10_enterprise.py     # → rag_traces.jsonl
```

### 2. 做项目

```text
docs/index.html
  ↓
docs/03_工程方法论手册.html
  ↓
docs/rag-knowledge-map.html
  ↓
docs/rag-5d.html
  ↓
docs/ai-knowledge-hub.html
```

### 3. 快速回查

```text
docs/ai-knowledge-hub.html
  ↓
按主题 / 按问题 / 标准知识对象
  ↓
跳到概念页 / 代码页 / 工程页 / 5D / 知识地图
```

---

## 快速开始

```bash
# 1. 进入代码目录
cd rag/code

# 2. 创建虚拟环境（需要 Python 3.12，uv 管理）
uv venv --python 3.12
source .venv/bin/activate          # macOS / Linux
# .venv\Scripts\activate           # Windows

# 3. 安装依赖
uv pip install openai numpy python-dotenv chromadb

# v6 额外依赖（首次运行会下载 bge-reranker-base 模型 ~270MB）
uv pip install sentence-transformers

# 4. 配置 API Key
cp .env.example .env
# 编辑 .env，填入 API Key 并设置 PROVIDER

# 5. 验证连通性
python 00_配置提供商_先改这个.py

# 6. 按顺序运行
python 01_v1_最小RAG循环.py
python 02_v2_文档分块策略.py
python 03_v3.5_黄金数据集.py     # 生成 baseline.json
python 04_v4_embedding选型.py     # 生成 v4_embedding_result.json
python 05_v5_混合检索.py          # 生成 v5_hybrid_result.json
python 06_v6_reranking.py         # 生成 v6_reranking_result.json（首次下载模型 ~270MB）
python 07_v7_query变换.py         # 生成 v7_query_transform_result.json
python 08_v8_评估框架.py          # 生成 v8_eval_result.json
python 09_v9_agentic_rag.py       # 生成 v9_agentic_result.json
python 10_v10_enterprise.py       # 生成 rag_traces.jsonl
```

> **Python 版本说明**：需要 Python 3.12。`chromadb` 依赖的 `onnxruntime` 暂不支持 Python 3.13，请勿使用系统默认的 Python 3.13。

如果你只是看文档，不需要先跑代码；如果你只是查术语，也不需要先通读路线图。

---

## 知识库化约定

这套 docs 现在按“知识库”而不是“散文档”维护，约定如下：

- `index.html` 是唯一统一入口，其他页面不再承担首页职责。
- 核心页面都说明“这页负责什么 / 不负责什么 / 下一步去哪”。
- `ai-knowledge-hub.html` 负责标准知识对象、术语、参数速查和问题索引。
- 高频知识点会逐步收敛成统一对象结构，方便后续做站内检索和 RAG 抽取。
- `knowledge-updates.html` 用于记录结构变化和重要内容更新。

---

## 国内模型选型

| 提供商 | 申请地址 | 环境变量 | 推荐场景 |
|--------|----------|----------|----------|
| 硅基流动 ★ | `siliconflow.cn` | `SILICONFLOW_API_KEY` | 学习首选，一个 key 搞定 embedding + chat |
| 智谱 AI | `open.bigmodel.cn` | `ZHIPU_API_KEY` | GLM-4-Flash 免费 |
| 通义千问 | `dashscope.aliyuncs.com` | `DASHSCOPE_API_KEY` | 企业级稳定 |
| OpenAI | `platform.openai.com` | `OPENAI_API_KEY` | 国际用户 |

---

课程和文档会持续更新。下一步会继续把更多知识点收敛成标准知识对象，并补机器可消费的知识索引。
