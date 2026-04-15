---
title: "ChromaDB 数据查看指南"
date: 2026-03-29
tags: ["ai-handbook", "rag"]
---

# ChromaDB 数据查看指南

## 图形化工具

### 1. DB Browser for SQLite（最简单）

ChromaDB 底层是 SQLite，无需额外依赖，直接打开文件：

```bash
open interview_kb/chroma.sqlite3
```

下载地址：https://sqlitebrowser.org
关键表：`embeddings` / `embedding_metadata` / `collections`

---

### 2. chromadb-admin（Web UI）

```bash
pip install chromadb-admin
python -m chromadb_admin --path interview_kb
```

浏览器打开 http://localhost:8000，可浏览、搜索 collection。

---

### 3. UMAP 聚类可视化

查看不同 topic 的 chunk 是否语义分区明显。

```bash
pip install umap-learn matplotlib
```

```python
import chromadb
import numpy as np
import matplotlib.pyplot as plt
from umap import UMAP

col = chromadb.PersistentClient(path="interview_kb").get_collection("ai_handbook")
res = col.get(include=["embeddings", "metadatas"])

embs   = np.array(res["embeddings"])
topics = [m["topic"] for m in res["metadatas"]]
coords = UMAP(n_components=2, random_state=42).fit_transform(embs)

colors = {"rag": "blue", "mcp": "green", "agent": "orange", "interview": "red"}
for topic, color in colors.items():
    idx = [i for i, t in enumerate(topics) if t == topic]
    plt.scatter(coords[idx, 0], coords[idx, 1], c=color, label=topic, alpha=0.6, s=10)

plt.legend()
plt.title("ChromaDB chunks by topic")
plt.savefig("kb_viz.png", dpi=150)
print("saved kb_viz.png")
```

理想结果：不同 topic 的点应有明显聚类。

---

## 命令行查看

### 基本信息 + 分块抽样

```python
import chromadb

col = chromadb.PersistentClient(path="interview_kb").get_collection("ai_handbook")

# 总量和版本
print(col.count())
print(col.metadata)

# 前 5 个 chunk（看分块效果）
res = col.get(limit=5, include=["documents", "metadatas"])
for doc, meta in zip(res["documents"], res["metadatas"]):
    print(f"[{meta['topic']}] {meta['source']}")
    print(doc[:200])
    print("---")

# 按 topic 统计 chunk 数
for topic in ["rag", "mcp", "agent", "interview"]:
    r = col.get(where={"topic": topic}, include=[])
    print(f"{topic:12s}: {len(r['ids'])} chunks")
```

---

### 检索质量测试

在 `rag/code/` 目录下运行：

```python
from importlib.util import module_from_spec, spec_from_file_location
import chromadb

# 加载 embed 函数
spec = spec_from_file_location("p", "00_配置提供商_先改这个.py")
mod  = module_from_spec(spec)
spec.loader.exec_module(mod)
embed = mod.embed

col = chromadb.PersistentClient(path="interview_kb").get_collection("ai_handbook")

queries = [
    ("RRF 互惠排名融合原理", "rag"),
    ("MCP 三类能力",         "mcp"),
    ("什么是 Agentic RAG",  "rag"),
]

for query, topic in queries:
    print(f"\n{'─'*50}")
    print(f"查询: {query}  [topic={topic}]")
    res = col.query(
        query_embeddings=[embed(query).tolist()],
        n_results=3,
        where={"topic": topic},
        include=["documents", "metadatas", "distances"],
    )
    for doc, meta, dist in zip(res["documents"][0], res["metadatas"][0], res["distances"][0]):
        score = round(1 - dist, 3)
        print(f"\n  [{score}] {meta['source']}")
        print(f"  {doc[:300]}")
```

---

## 检索质量判断标准

| 得分 | 评价 |
|---|---|
| > 0.8 | 很好 |
| 0.6 ~ 0.8 | 可用 |
| < 0.6 | 需优化分块策略或更换 embedding 模型 |

**分块质量检查要点：**
- chunk 开头应有面包屑标题，如 `[混合检索 > RRF 算法]`
- 不应命中导航栏、按钮等 UI 文字
- 单个 chunk 长度建议 100~500 字
