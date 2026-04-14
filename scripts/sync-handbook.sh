#!/usr/bin/env bash
# sync-handbook.sh — 将 ai-handbook 知识库同步到 Quartz 博客
# 用法: ./scripts/sync-handbook.sh [HANDBOOK_PATH]
#
# 同步策略:
#   .md   → content/ai-handbook/  (自动注入 frontmatter，构建前执行)
#   .html → public/ai-handbook/   (构建后执行，因为 quartz build 会清空 public/)
#
# 阶段:
#   ./scripts/sync-handbook.sh           — 仅同步 md（pre-build 默认）
#   ./scripts/sync-handbook.sh --html    — 仅复制 html（post-build）
#   ./scripts/sync-handbook.sh --all     — 两步都做（手动全量同步）
#
# 幂等：可反复执行，结果一致

set -euo pipefail

BLOG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 解析参数：支持 --html / --all，以及可选的 HANDBOOK_PATH
MODE="md"
HANDBOOK="$HOME/workspace/ai-handbook"
for arg in "$@"; do
  case "$arg" in
    --html) MODE="html" ;;
    --all)  MODE="all" ;;
    -*)     echo "Unknown option: $arg"; exit 1 ;;
    *)      HANDBOOK="$arg" ;;
  esac
done

# 转为绝对路径
HANDBOOK="$(cd "$HANDBOOK" && pwd)"

CONTENT_DEST="$BLOG_ROOT/content/ai-handbook"
PUBLIC_DEST="$BLOG_ROOT/public/ai-handbook"

# ── 工具函数 ──────────────────────────────────────────

# 从 md 文件提取 title：取第一个 # 标题，否则用文件名
extract_title() {
  local file="$1"
  local basename="$2"
  local title
  title=$(grep -m1 '^# ' "$file" | sed 's/^# //' | sed 's/["\]/\\&/g')
  if [[ -z "$title" ]]; then
    title=$(echo "$basename" | sed 's/\.md$//' | sed 's/^[0-9_-]*//' | sed 's/-/ /g' | sed 's/_/ /g')
  fi
  echo "$title"
}

# 从 git 获取文件最后修改日期，fallback 到文件系统
get_date() {
  local file="$1"
  local date
  date=$(cd "$HANDBOOK" && git log -1 --format="%aI" -- "${file#$HANDBOOK/}" 2>/dev/null | cut -d'T' -f1)
  if [[ -z "$date" ]]; then
    # Linux 兼容: 优先 GNU stat，fallback macOS stat
    date=$(stat -c "%Y" "$file" 2>/dev/null | xargs -I{} date -d @{} +%Y-%m-%d 2>/dev/null \
      || stat -f "%Sm" -t "%Y-%m-%d" "$file" 2>/dev/null \
      || date +%Y-%m-%d)
  fi
  echo "$date"
}

# 根据路径生成 tags
path_to_tags() {
  local relpath="$1"
  local tags=("ai-handbook")
  local first_dir
  first_dir=$(echo "$relpath" | cut -d'/' -f1)
  case "$first_dir" in
    mcp) tags+=("mcp") ;;
    agent|agent-research) tags+=("agent") ;;
    rag) tags+=("rag") ;;
    ai-programming) tags+=("ai-programming") ;;
    methodology) tags+=("methodology") ;;
  esac
  local result="["
  for t in "${tags[@]}"; do
    result="$result\"$t\", "
  done
  result="${result%, }]"
  echo "$result"
}

# 注入 frontmatter（如果文件已有则跳过）
inject_frontmatter() {
  local src="$1"
  local dest="$2"
  local relpath="$3"

  local basename
  basename=$(basename "$src")
  local title
  title=$(extract_title "$src" "$basename")
  local date
  date=$(get_date "$src")
  local tags
  tags=$(path_to_tags "$relpath")

  if head -1 "$src" | grep -q '^---$'; then
    cp "$src" "$dest"
    return
  fi

  cat > "$dest" <<FRONTMATTER
---
title: "$title"
date: $date
tags: $tags
---

FRONTMATTER
  cat "$src" >> "$dest"
}

# ── 阶段 1: 同步 Markdown ─────────────────────────────

sync_markdown() {
  echo "==> [pre-build] 同步 Markdown → content/ai-handbook/"

  rm -rf "$CONTENT_DEST"
  mkdir -p "$CONTENT_DEST"

  local md_count=0
  while IFS= read -r -d '' file; do
    local relpath="${file#$HANDBOOK/}"

    # 跳过不适合发布的文件
    case "$relpath" in
      CLAUDE.md|*/CLAUDE.md|*/PLAN.md|*/SKILL.md) continue ;;
      */skills/*.md) continue ;;
    esac

    local dest="$CONTENT_DEST/$relpath"
    mkdir -p "$(dirname "$dest")"
    inject_frontmatter "$file" "$dest" "$relpath"
    md_count=$((md_count + 1))
  done < <(find "$HANDBOOK" \
    -type f -name "*.md" \
    -not \( -path '*/.venv/*' -o -path '*/node_modules/*' -o -path '*/.pytest_cache/*' \
            -o -path '*/.claude/*' -o -path '*/.git/*' -o -path '*/dist-info/*' \
            -o -path '*/__pycache__/*' -o -path '*/.omc/*' -o -path '*/dist/*' \) \
    -print0)

  # 生成索引页
  generate_index

  echo "    同步 $md_count 个 md + 索引页"
}

# ── 阶段 2: 复制 HTML ─────────────────────────────────

sync_html() {
  echo "==> [post-build] 复制 HTML → public/ai-handbook/"

  mkdir -p "$PUBLIC_DEST"

  local html_count=0
  while IFS= read -r -d '' file; do
    local relpath="${file#$HANDBOOK/}"
    local dest="$PUBLIC_DEST/$relpath"
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
    html_count=$((html_count + 1))
  done < <(find "$HANDBOOK" \
    -type f -name "*.html" \
    -not \( -path '*/.venv/*' -o -path '*/node_modules/*' -o -path '*/src/*' \
            -o -path '*/.git/*' \) \
    -print0)

  echo "    复制 $html_count 个 html 文件"
}

# ── 生成索引页 ──────────────────────────────────────

generate_index() {
  local INDEX="$CONTENT_DEST/index.md"
  cat > "$INDEX" <<'EOF'
---
title: "AI Handbook · AI 工程师知识手册"
date: 2026-04-14
tags: ["ai-handbook"]
---

让知识以地图的形式呈现在你的脑中。

> AI 应用工程师的完整学习记录。包含深度追问过程、真实误解纠错、和可在浏览器直接打开的交互式笔记。

## 知识地图

### MCP · 模型上下文协议

- [MCP 基础：是什么、解决什么、为什么重要](mcp/01-foundations/README.md)
- [三类能力：Tools / Resources / Prompts](mcp/02-core-concepts/tools-resources-prompts.md)
- [Function Calling 前世今生](mcp/02-core-concepts/function-calling.md)
- [Adapter & Gateway 实战架构](mcp/03-practical/adapter-gateway.md)
- [MCP 面试题库](mcp/05-interview/qa.md)
- [理解错的 10 件事](mcp/05-interview/common-misconceptions.md)

### Agent · AI 智能体

- [Agent Planning & Reasoning](agent/planning-reasoning-README.md)

### Agent Research · 生态拆解

- [ATDF 方法论](agent-research/methodology/ATDF.md)
- [Agent 生态 2026](agent-research/research/agent-ecosystem-2026.md)
- [OMC 拆解](agent-research/deep-dives/omc/omc-atdf.md)
- [gstack 拆解](agent-research/deep-dives/gstack/gstack-atdf.md)
- [从 RAG 到 Memory](agent-research/concepts/rag-to-memory.md)
- [Karpathy 路线](agent-research/concepts/karpathy-route.md)

### RAG · 检索增强生成

- [RAG 概览](rag/README.md)
- [企业级应用参考及 RAG 生态](rag/docs/企业级应用参考及rag生态.md)

### AI Programming · 编程实战

- [OMC PM Audio 案例](ai-programming/cases/omc-pm-audio-cs.md)

### 方法论

- [学习方法论](methodology/README.md)

---

## 交互式笔记 (HTML)

> 这些是独立的交互式页面，点击后在新窗口打开。

### MCP 交互笔记
- [MCP 深挖 · 11 问](/ai-handbook/mcp/interactive/mcp_11q.html){target="_blank"}
- [MCP 机制追问 · 5 问](/ai-handbook/mcp/interactive/mcp_5q.html){target="_blank"}

### Agent 交互笔记
- [Agent 5D 知识地图](/ai-handbook/agent/agent-5d-v3.html){target="_blank"}
- [Planning & Reasoning 5D](/ai-handbook/agent/planning-reasoning-5d-v4.html){target="_blank"}
- [Agent 生态 2026 交互版](/ai-handbook/agent-research/research/agent-ecosystem-2026.html){target="_blank"}
- [MemGPT/Letta 指南](/ai-handbook/agent-research/deep-dives/memgpt-letta/memgpt-letta-guide.html){target="_blank"}

### RAG 交互笔记
- [RAG 知识地图](/ai-handbook/rag/docs/rag-knowledge-map.html){target="_blank"}
- [RAG 5D](/ai-handbook/rag/docs/rag-5d.html){target="_blank"}
- [AI 知识中枢](/ai-handbook/rag/docs/ai-knowledge-hub.html){target="_blank"}
- [课程路线图](/ai-handbook/rag/docs/00_课程路线图.html){target="_blank"}
- [理解 RAG](/ai-handbook/rag/docs/01_理解RAG.html){target="_blank"}
- [向量与检索](/ai-handbook/rag/docs/02_概念手册_向量与检索.html){target="_blank"}
- [代码讲解 V1V2](/ai-handbook/rag/docs/03_代码讲解_V1V2.html){target="_blank"}
- [工程方法论手册](/ai-handbook/rag/docs/04_工程方法论手册.html){target="_blank"}

### AI Programming 交互笔记
- [AI 编程总览](/ai-handbook/ai-programming/dist/ai-programming.html){target="_blank"}
- [AI 案例集](/ai-handbook/ai-programming/dist/ai-cases.html){target="_blank"}
- [AI 工具集](/ai-handbook/ai-programming/dist/ai-tools.html){target="_blank"}
- [OMC 深度分析](/ai-handbook/ai-programming/dist/omc-deep-dive.html){target="_blank"}
- [AI 修炼册](/ai-handbook/ai-programming/ai-xiulian-ce.html){target="_blank"}
- [OMC 工程分析](/ai-handbook/ai-programming/omc-engineering.html){target="_blank"}
- [OMC 分析](/ai-handbook/ai-programming/omc-analysis.html){target="_blank"}
- [Skill 自动提取](/ai-handbook/ai-programming/skill-auto-extract.html){target="_blank"}

### 方法论交互笔记
- [学习方法论交互版](/ai-handbook/methodology/interactive.html){target="_blank"}
EOF
}

# ── 主入口 ──────────────────────────────────────────

echo "==> sync-handbook (mode: $MODE)"
echo "    来源: $HANDBOOK"
echo "    博客: $BLOG_ROOT"
echo ""

case "$MODE" in
  md)   sync_markdown ;;
  html) sync_html ;;
  all)  sync_markdown; sync_html ;;
esac

echo ""
echo "==> Done!"
