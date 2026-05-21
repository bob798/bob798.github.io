---
title: "终端找文件神器：mdfind 与 fd 使用指南"
date: 2026-05-21
description: "macOS 全盘秒搜的 mdfind，加项目内极速查找的 fd，组合起来覆盖 99% 的终端找文件场景"
tags: ["macos", "cli", "dev-tools", "productivity"]
draft: false
---

> 终端找文件，`find` 用了几十年，但慢、语法繁琐。现代方案是 **`mdfind`（全盘）+ `fd`（项目内）** 组合，秒级响应。

## 一、`fd` —— `find` 的现代替代

### 名字由来

`fd` 是 `find` 的缩写，用 Rust 写的现代命令行工具，主打**更快、更短、更友好**。

- GitHub：https://github.com/sharkdp/fd
- 默认忽略 `.gitignore` 中的文件
- 默认忽略隐藏文件
- 彩色输出、并行搜索

### 安装

```bash
brew install fd
```

### 基本用法

```bash
fd PATTERN [PATH]
```

不指定 PATH 时，默认从当前目录递归搜索。

### 常用示例

```bash
# 模糊匹配文件名
fd readme

# 在指定目录搜索
fd config ~/projects

# 按扩展名搜索
fd -e md                    # 所有 .md 文件
fd -e py -e js              # .py 或 .js

# 包含隐藏文件
fd -H .env

# 包含 .gitignore 中的文件
fd -I node_modules

# 同时包含隐藏文件 + gitignore
fd -HI 关键词

# 只找文件 / 只找目录
fd -t f pattern             # file
fd -t d pattern             # directory

# 正则模式
fd '^test_.*\.py$'

# 大小写敏感（默认智能：全小写→忽略大小写）
fd -s Pattern

# 按修改时间过滤
fd --changed-within 1d      # 一天内修改的
fd --changed-before 1week   # 一周前的

# 找到后执行命令（类似 find -exec）
fd -e log -x rm             # 删除所有 .log
fd -e jpg -x convert {} {.}.png   # 批量转换格式
```

### `find` vs `fd` 对照

| 任务 | find | fd |
|------|------|----|
| 找名字含 foo 的文件 | `find . -iname "*foo*"` | `fd foo` |
| 找所有 md 文件 | `find . -name "*.md"` | `fd -e md` |
| 找目录 | `find . -type d -name "src"` | `fd -t d src` |
| 删除所有 log | `find . -name "*.log" -delete` | `fd -e log -x rm` |

`fd` 命令更短，默认行为更符合直觉。

---

## 二、`mdfind` —— macOS Spotlight 命令行

### 名字由来

`md` = **metadata**（macOS Spotlight 用文件元数据建索引），`find` 就是查找。
合起来 `mdfind` = **metadata find**，调用的就是 Spotlight 索引。

- 系统自带，无需安装
- **全盘秒搜**（提前建好了索引）
- 不仅搜文件名，还能搜**文件内容**

### 基本用法

```bash
mdfind QUERY
```

### 常用示例

```bash
# 搜索文件名或内容包含关键词的文件（全盘）
mdfind "项目计划"

# 只匹配文件名
mdfind -name "config.json"

# 限定搜索目录
mdfind -onlyin ~/Documents "简历"
mdfind -onlyin ~/Downloads "发票"

# 按文件类型
mdfind "kind:pdf 合同"
mdfind "kind:image 截图"
mdfind "kind:folder 工作"

# 按时间
mdfind "kMDItemFSContentChangeDate > \$time.today"
mdfind "kMDItemFSContentChangeDate > \$time.this_week"

# 按作者 / 应用
mdfind "kMDItemAuthors == 'Bob'"

# 只显示个数
mdfind -count "kind:pdf"

# 实时监听（文件出现时立刻打印）
mdfind -live "新需求"
```

### 常用 kind 关键词

| kind | 类型 |
|------|------|
| `kind:pdf` | PDF 文档 |
| `kind:image` | 图片 |
| `kind:movie` | 视频 |
| `kind:music` | 音频 |
| `kind:folder` | 文件夹 |
| `kind:application` | 应用程序 |
| `kind:email` | 邮件 |
| `kind:contact` | 联系人 |
| `kind:bookmark` | 书签 |

### 查看任意文件的元数据

```bash
mdls /path/to/file
```

可以看到 Spotlight 给该文件打了哪些标签，方便构造精准查询。

---

## 三、`fd` vs `mdfind` 怎么选？

| 场景 | 推荐 |
|------|------|
| 项目代码内找文件 | **`fd`** |
| 知道大致目录，找文件名 | **`fd`** |
| 全盘找一个想不起来在哪的文件 | **`mdfind`** |
| 按文件**内容**搜索 | **`mdfind`** 或 `rg`（ripgrep） |
| 按文件类型/作者/时间等元数据 | **`mdfind`** |
| 想忽略 `.gitignore`、`node_modules` | **`fd`** |
| Linux 环境 | **`fd`**（mdfind 是 macOS 专属） |

### 我的日常工作流

```bash
# 在项目里
fd 关键词

# 全盘找文档
mdfind -onlyin ~/Documents "关键词"

# 找代码内容
rg "function_name"
```

`fd` + `mdfind` + `rg`（ripgrep）= 终端找东西的黄金组合。

---

## 四、配合 `fzf` 模糊搜索更爽

把 `fd` 输出喂给 `fzf`，做交互式模糊筛选：

```bash
# 模糊找文件并用 vim 打开
vim "$(fd -t f | fzf)"

# 模糊跳转目录
cd "$(fd -t d | fzf)"
```

写进 `.zshrc` 做成快捷键，找文件这件事就再也不烦了。

---

## 小结

- **`fd`** = `find` 现代版，**项目内**搜文件首选
- **`mdfind`** = macOS Spotlight CLI，**全盘** + **按内容/元数据**搜索的王者
- 两个工具语法都很短，记几个核心参数就能覆盖 90% 场景
- 配合 `rg` 搜内容、`fzf` 做模糊筛选，终端效率直接拉满
