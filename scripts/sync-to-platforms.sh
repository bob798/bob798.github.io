#!/bin/bash
# 博客文章一键同步到多平台
# 前置条件：Chrome 打开并登录各平台 + WechatSync 扩展已启用 MCP Connection
#
# 用法:
#   ./scripts/sync-to-platforms.sh                     # 同步最新一篇文章
#   ./scripts/sync-to-platforms.sh content/posts/xxx.md # 同步指定文章
#   ./scripts/sync-to-platforms.sh --all-new            # 同步所有今天的文章
#   ./scripts/sync-to-platforms.sh --dry-run             # 预览，不实际同步

set -euo pipefail

CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)/content/posts"
PLATFORMS="zhihu,juejin,woshipm,csdn,segmentfault,jianshu"
DRY_RUN=""

# Parse args
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    shift
fi

sync_file() {
    local file="$1"
    local filename=$(basename "$file")
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  同步: $filename"
    echo "  平台: $PLATFORMS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    wechatsync sync "$file" -p "$PLATFORMS" $DRY_RUN
    echo "  完成!"
}

if [[ "${1:-}" == "--all-new" ]]; then
    # 同步今天的所有文章
    TODAY=$(date +%Y-%m-%d)
    echo "同步今天 ($TODAY) 的所有文章..."
    found=0
    for file in "$CONTENT_DIR"/${TODAY}*.md; do
        [[ -f "$file" ]] || continue
        # 跳过 draft
        if head -10 "$file" | grep -q "draft: true"; then
            echo "跳过 draft: $(basename "$file")"
            continue
        fi
        sync_file "$file"
        found=$((found + 1))
    done
    if [[ $found -eq 0 ]]; then
        echo "今天没有新文章"
    else
        echo ""
        echo "共同步 $found 篇文章"
    fi
elif [[ -n "${1:-}" ]]; then
    # 同步指定文件
    sync_file "$1"
else
    # 同步最新一篇文章（按文件名日期排序）
    LATEST=$(ls -1 "$CONTENT_DIR"/*.md 2>/dev/null | grep -v "^_" | sort -r | head -1)
    if [[ -z "$LATEST" ]]; then
        echo "没有找到文章"
        exit 1
    fi
    echo "同步最新文章..."
    sync_file "$LATEST"
fi
