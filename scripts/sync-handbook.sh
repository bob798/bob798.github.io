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

## 顶层 series 显示名映射 + 推荐顺序
## 新增 series 不在映射里时，自动用目录名兜底，并附加在末尾
series_display_name() {
  case "$1" in
    mcp)             echo "MCP · 模型上下文协议" ;;
    agent)           echo "Agent · AI 智能体" ;;
    agent-research)  echo "Agent Research · 生态拆解" ;;
    rag)             echo "RAG · 检索增强生成" ;;
    ai-programming)  echo "AI Programming · 编程实战" ;;
    methodology)     echo "方法论" ;;
    *)               echo "$1" ;;
  esac
}

## 跳过非内容目录
is_skipped_dir() {
  case "$1" in
    .git|.github|node_modules|.venv|.pytest_cache|.claude|.omc|.idea|.vscode|dist|build|src|skills|public|_handbook|__pycache__) return 0 ;;
    *) return 1 ;;
  esac
}

## 提取 README 描述行（首段非空非标题行，截断 120 字）
extract_readme_desc() {
  local readme="$1"
  [[ -f "$readme" ]] || { echo ""; return; }
  awk '
    /^---$/ { fm = !fm; next }
    fm { next }
    /^#/   { next }
    /^>/   { sub(/^> */, ""); print; exit }
    NF > 0 { print; exit }
  ' "$readme" | cut -c1-120
}

generate_index() {
  local INDEX="$CONTENT_DEST/index.md"

  cat > "$INDEX" <<'HEADER'
---
title: "AI Handbook · AI 工程师知识手册"
date: 2026-04-14
tags: ["ai-handbook"]
---

让知识以地图的形式呈现在你的脑中。

> AI 应用工程师的完整学习记录。包含深度追问过程、真实误解纠错、和可在浏览器直接打开的交互式笔记。

## 知识地图

HEADER

  ## ── 动态生成: 知识地图 ────────────────────────────
  ## 推荐顺序（学习路径），未列出的目录追加在末尾（按字母序）
  local ORDER=(mcp agent agent-research rag ai-programming methodology)
  local processed=()

  emit_series_section() {
    local dirname="$1"
    local src_dir="$HANDBOOK/$dirname"
    [[ -d "$src_dir" ]] || return

    local display
    display=$(series_display_name "$dirname")

    echo "" >> "$INDEX"
    echo "### $display" >> "$INDEX"
    echo "" >> "$INDEX"

    # README 描述行（若存在）
    local desc
    desc=$(extract_readme_desc "$src_dir/README.md")
    if [[ -n "$desc" ]]; then
      echo "$desc" >> "$INDEX"
      echo "" >> "$INDEX"
    fi

    # 系列入口：优先 README.md，没有就给目录链接
    if [[ -f "$src_dir/README.md" ]]; then
      echo "- [系列概览 →]($dirname/README.md)" >> "$INDEX"
    else
      echo "- [系列目录 →]($dirname/)" >> "$INDEX"
    fi

    # 列出最多 6 个代表性 md（深度 ≤ 2，跳过 README）
    local count=0
    while IFS= read -r -d '' file; do
      [[ $count -ge 6 ]] && break
      local relpath="${file#$HANDBOOK/}"
      local basename
      basename=$(basename "$file")
      case "$basename" in
        README.md|CLAUDE.md|PLAN.md|SKILL.md|index.md) continue ;;
      esac
      local title
      title=$(extract_title "$file" "$basename")
      echo "- [$title]($relpath)" >> "$INDEX"
      count=$((count + 1))
    done < <(find "$src_dir" -maxdepth 2 -type f -name "*.md" -print0 2>/dev/null | sort -z)
  }

  # 1. 按推荐顺序输出已知 series
  for dirname in "${ORDER[@]}"; do
    [[ -d "$HANDBOOK/$dirname" ]] || continue
    emit_series_section "$dirname"
    processed+=("$dirname")
  done

  # 2. 扫描剩余 top-level 目录（未在 ORDER 里的新 series）
  for path in "$HANDBOOK"/*/; do
    local dirname
    dirname=$(basename "$path")
    is_skipped_dir "$dirname" && continue
    # 已处理过？
    local already=0
    for p in "${processed[@]}"; do [[ "$p" == "$dirname" ]] && already=1; done
    [[ $already -eq 1 ]] && continue
    emit_series_section "$dirname"
  done

  ## ── 动态生成: 交互式笔记列表 ────────────────────────
  ## 只在有 html 文件时输出该 section
  local html_count
  html_count=$(find "$HANDBOOK" -type f -name "*.html" \
    -not \( -path '*/.venv/*' -o -path '*/node_modules/*' -o -path '*/src/*' \
            -o -path '*/.git/*' \) 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$html_count" -gt 0 ]]; then
    cat >> "$INDEX" <<'INTERACTIVE'

---

## 交互式笔记

> 嵌入式交互页面，可在博客内直接查看，也可新窗口打开。
INTERACTIVE

    local current_section=""
    while IFS= read -r -d '' file; do
      local relpath="${file#$HANDBOOK/}"
      local basename
      basename=$(basename "$file")
      local first_dir
      first_dir=$(echo "$relpath" | cut -d'/' -f1)
      local section_name
      section_name="$(series_display_name "$first_dir") · 交互笔记"

      if [[ "$section_name" != "$current_section" ]]; then
        echo "" >> "$INDEX"
        echo "### $section_name" >> "$INDEX"
        current_section="$section_name"
      fi

      local title
      title=$(extract_html_title "$file" "$basename")
      local md_relpath="${relpath%.html}.md"
      echo "- [$title]($md_relpath)" >> "$INDEX"
    done < <(find "$HANDBOOK" \
      -type f -name "*.html" \
      -not \( -path '*/.venv/*' -o -path '*/node_modules/*' -o -path '*/src/*' \
              -o -path '*/.git/*' \) \
      -print0 | sort -z)
  fi
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
