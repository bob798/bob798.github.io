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

# 从 HTML <title> 标签提取标题，fallback 到文件名
extract_html_title() {
  local file="$1"
  local basename="$2"
  local title
  title=$(grep -m1 '<title>' "$file" | sed 's/.*<title>//' | sed 's/<\/title>.*//' | sed 's/["\]/\\&/g')
  if [[ -z "$title" ]]; then
    title=$(echo "$basename" | sed 's/\.html$//' | sed 's/^[0-9_-]*//' | sed 's/-/ /g' | sed 's/_/ /g')
  fi
  echo "$title"
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

# 为 HTML 文件生成 wrapper .md（iframe 嵌入），使其出现在左侧导航
generate_html_wrappers() {
  local wrapper_count=0
  while IFS= read -r -d '' file; do
    local relpath="${file#$HANDBOOK/}"

    local basename
    basename=$(basename "$file")
    local title
    title=$(extract_html_title "$file" "$basename")
    local date
    date=$(get_date "$file")
    local tags
    tags=$(path_to_tags "$relpath")

    # wrapper md 路径：与 html 同名但扩展名为 .md
    local md_relpath="${relpath%.html}.md"
    local dest="$CONTENT_DEST/$md_relpath"

    # 如果同名 .md 已经由 markdown 同步阶段写入，跳过
    [[ -f "$dest" ]] && continue

    mkdir -p "$(dirname "$dest")"
    cat > "$dest" <<WRAPPER
---
title: "$title"
date: $date
tags: $tags
---

<style>
.html-embed-container { position: relative; width: 100%; }
.html-embed-container iframe { width: 100%; height: 85vh; border: none; border-radius: 8px; }
.html-embed-fullscreen { position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; z-index: 9999; background: #fff; }
.html-embed-fullscreen iframe { height: 100vh; border-radius: 0; }
.html-embed-controls { display: flex; gap: 8px; margin-bottom: 8px; }
.html-embed-controls a, .html-embed-controls button { padding: 4px 12px; border: 1px solid #ddd; border-radius: 4px; background: #f8f8f8; cursor: pointer; font-size: 13px; text-decoration: none; color: inherit; }
.html-embed-controls button:hover, .html-embed-controls a:hover { background: #eee; }
</style>

<div class="html-embed-controls">
<a href="https://bob798.github.io/ai-handbook/_html/$relpath" target="_blank">↗ 新窗口打开</a>
<button onclick="this.closest('.html-embed-controls').nextElementSibling.classList.toggle('html-embed-fullscreen')">⛶ 全屏</button>
</div>
<div class="html-embed-container">
<iframe src="https://bob798.github.io/ai-handbook/_html/$relpath" loading="lazy"></iframe>
</div>
WRAPPER
    wrapper_count=$((wrapper_count + 1))
  done < <(find "$HANDBOOK" \
    -type f -name "*.html" \
    -not \( -path '*/.venv/*' -o -path '*/node_modules/*' -o -path '*/src/*' \
            -o -path '*/.git/*' \) \
    -print0)

  echo "    生成 $wrapper_count 个 HTML wrapper md"
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

  # 为 HTML 生成 wrapper md
  generate_html_wrappers

  # 生成索引页
  generate_index

  echo "    同步 $md_count 个 md + 索引页"
}

# ── 阶段 2: 复制 HTML ─────────────────────────────────

sync_html() {
  local HTML_DEST="$PUBLIC_DEST/_html"
  echo "==> [post-build] 复制 HTML → public/ai-handbook/_html/"

  mkdir -p "$HTML_DEST"

  local html_count=0
  while IFS= read -r -d '' file; do
    local relpath="${file#$HANDBOOK/}"
    local dest="$HTML_DEST/$relpath"
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

  # ── 静态部分: 知识地图 ──
  cat > "$INDEX" <<'HEADER'
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

## 交互式笔记

> 嵌入式交互页面，可在博客内直接查看，也可新窗口打开。

HEADER

  # ── 动态部分: 自动扫描 HTML 生成交互笔记列表 ──
  # 目录名 → 显示名映射
  local current_section=""
  while IFS= read -r -d '' file; do
    local relpath="${file#$HANDBOOK/}"
    local basename
    basename=$(basename "$file")

    # 提取所属目录（第一级）
    local first_dir
    first_dir=$(echo "$relpath" | cut -d'/' -f1)

    # 分组标题
    local section_name=""
    case "$first_dir" in
      mcp)              section_name="MCP 交互笔记" ;;
      agent)            section_name="Agent 交互笔记" ;;
      agent-research)   section_name="Agent Research 交互笔记" ;;
      rag)              section_name="RAG 交互笔记" ;;
      ai-programming)   section_name="AI Programming 交互笔记" ;;
      methodology)      section_name="方法论交互笔记" ;;
      *)                section_name="其他交互笔记" ;;
    esac

    # 输出分组标题（去重）
    if [[ "$section_name" != "$current_section" ]]; then
      echo "" >> "$INDEX"
      echo "### $section_name" >> "$INDEX"
      current_section="$section_name"
    fi

    # 提取标题
    local title
    title=$(extract_html_title "$file" "$basename")

    # 链接到 wrapper md（去掉 .html 换成 .md）
    local md_relpath="${relpath%.html}.md"
    echo "- [$title]($md_relpath)" >> "$INDEX"

  done < <(find "$HANDBOOK" \
    -type f -name "*.html" \
    -not \( -path '*/.venv/*' -o -path '*/node_modules/*' -o -path '*/src/*' \
            -o -path '*/.git/*' \) \
    -print0 | sort -z)
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
