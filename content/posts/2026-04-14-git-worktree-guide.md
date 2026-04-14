---
title: "Git Worktree 实用指南：优势、坑点与最佳实践"
date: 2026-04-14
description: "Git worktree 的常见问题、使用场景和避坑指南"
tags: ["tools", "blog"]
draft: true
---

> Git worktree 本身很稳定，但实际使用中有几个容易踩的坑。

## 常见问题

### 1. 分支锁定

同一个分支不能同时被两个 worktree 使用。

```bash
git worktree add ../fix main
# error: 'main' is already checked out at '/path/to/repo'
```

### 2. 删除不干净

直接 `rm -rf` worktree 目录会留下残留记录，导致分支无法被 checkout。

```bash
# 错误做法
rm -rf ../my-worktree

# 正确做法
git worktree remove ../my-worktree

# 如果已经手动删了，用 prune 清理
git worktree prune
```

### 3. node_modules / 依赖不共享

每个 worktree 有独立的文件目录，`node_modules` 不会共享，需要各自 `npm install`。大项目会占用大量磁盘空间。

### 4. IDE 混乱

VS Code 打开多个 worktree 时，全局搜索、Git 面板可能指向错误的 worktree。建议每个 worktree 开独立的 VS Code 窗口。

### 5. .git 是文件不是目录

Worktree 里的 `.git` 是一个指向主仓库的文件，不是目录。某些工具（CI、脚本）假设 `.git` 是目录会报错。

### 6. 忘记清理

长期积累的 worktree 占磁盘空间，定期检查：

```bash
git worktree list    # 看看有哪些
git worktree prune   # 清理已删除目录的残留
```

## 什么时候该用 / 不该用

| 适合 | 不适合 |
|------|--------|
| 并行开发多个功能 | 只是想看另一个分支的代码（用 `git show` 更轻） |
| Claude Code 并行任务 | 频繁在分支间切换（`git switch` 更简单） |
| 长期维护多个版本 | 临时修一个小 bug（`git stash` 就够了） |

## 在 Claude Code 中使用 Worktree

### 启动时创建

```bash
claude --worktree feature-auth       # 指定名称
claude --worktree                    # 自动命名
claude --worktree feature-auth --tmux  # 在 tmux 中打开
```

### 会话中创建

直接对 Claude 说 "work in a worktree" 或 "start a worktree"，会自动创建。

### VS Code 中打开已有 Worktree

```bash
git worktree list          # 查看所有 worktree
code /path/to/worktree     # 用 VS Code 打开
```

VS Code 会自动识别 worktree 的 Git 上下文和分支，Claude Code 扩展也会自动跟随。

## 常用命令速查

```bash
# 创建
git worktree add ../feature-x feature-branch

# 查看
git worktree list

# 删除
git worktree remove ../feature-x

# 清理残留
git worktree prune
```
