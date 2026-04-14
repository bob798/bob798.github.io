#!/bin/bash
# Git post-push 钩子：推送后自动检测新文章并提示同步
# 安装方法：在博客仓库根目录运行
#   cp scripts/post-push-sync.sh .git/hooks/post-push && chmod +x .git/hooks/post-push
#
# 或者在 Claude Code settings.json 中配置为 hook

set -euo pipefail

# 检测本次推送是否包含新文章
NEW_POSTS=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep "^content/posts/.*\.md$" | grep -v "^_" || true)

if [[ -z "$NEW_POSTS" ]]; then
    exit 0
fi

echo ""
echo "================================================"
echo "  检测到新/更新的博客文章:"
echo "------------------------------------------------"
echo "$NEW_POSTS" | while read -r f; do echo "    $f"; done
echo "================================================"
echo ""
echo "  博客已自动部署到 bob798.github.io"
echo ""
echo "  同步到多平台（知乎/掘金/人人都是PM...）:"
echo "    ./scripts/sync-to-platforms.sh"
echo ""
echo "  预览（不实际同步）:"
echo "    ./scripts/sync-to-platforms.sh --dry-run"
echo ""
