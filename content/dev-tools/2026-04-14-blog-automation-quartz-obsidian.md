---
title: "从 Jekyll 到 Quartz：我的博客自动化全流程"
date: 2026-04-14
description: "用 Quartz + Obsidian + WechatSync 搭建写作→发布→多平台同步的自动化工作流"
tags: ["ai", "tools", "blog"]
---

> 写完文章，git push，博客自动上线，一条命令同步到知乎、掘金、人人都是产品经理。

## 背景

我的博客从 2018 年开始用 Jekyll 搭建在 GitHub Pages 上，一直没怎么更新。最近在 AI 领域做了不少东西，想把学习笔记和项目实践发出来，发现旧工具链有几个问题：

- **Jekyll 和 Obsidian 不兼容** — 写笔记用 Obsidian，发博客要手动转格式
- **没有自动部署** — 改完文章要本地构建再推送
- **多平台发布靠手动** — 知乎、掘金每个平台都要复制粘贴一遍

于是花了一天时间，把整个写作流程重建了一遍。

## 最终效果

```
Obsidian 写文章
    ↓
git push（唯一的手动操作）
    ↓
GitHub Actions 自动构建 → bob798.github.io 上线
    ↓
一条命令 → 知乎/掘金/人人都是PM/CSDN/简书 全部同步（草稿）
```

## 第一步：从 Jekyll 迁移到 Quartz

### 为什么选 Quartz

对比了 Hugo、Astro、Quartz 三个方案：

| 对比项 | Hugo | Astro | Quartz |
|--------|------|-------|--------|
| Obsidian 原生支持 | 需要转换工具（多已废弃） | 需要 remark 插件 | `[[wikilinks]]`、callouts 全支持 |
| GitHub Pages | 需自建 workflow | 需自建 workflow | 内置 GitHub Actions |
| 知识图谱 | 无 | 无 | 有 |
| 双向链接 | 无 | 无 | 自动生成 |
| Stars | 78k | 48k | 11.8k |

Hugo 和 Astro 本身很强，但和 Obsidian 的集成都不好。Quartz（[jackyzha0/quartz](https://github.com/jackyzha0/quartz)）是专门为 Obsidian 打造的静态站点生成器，零转换摩擦。

### 迁移过程

**1. 备份旧站点**

```bash
git checkout -b jekyll-backup
git push origin jekyll-backup
```

**2. 初始化 Quartz**

```bash
git clone https://github.com/jackyzha0/quartz.git
# 把 Quartz 文件复制到博客仓库（保留 .git）
npm install
```

**3. 迁移文章**

Jekyll 的文章在 `_posts/` 目录，frontmatter 格式是：

```yaml
---
layout: post
categories: ai
title: 文章标题
date: 2026-04-14
description: 描述
keywords: 关键词
---
```

Quartz 的文章在 `content/` 目录，frontmatter 更简单：

```yaml
---
title: "文章标题"
date: 2026-04-14
description: "描述"
tags: ["ai", "tools"]
---
```

写了一个 Python 脚本批量转换，主要是 `categories` → `tags`，去掉 `layout` 和 `keywords`。

**4. 配置站点**

`quartz.config.ts` 核心配置：

```ts
configuration: {
  pageTitle: "Bob's Garden",
  locale: "zh-CN",
  baseUrl: "bob798.github.io",
  defaultDateType: "created",
  enablePopovers: false,  // 关掉悬浮预览，更简洁
}
```

**5. 部署**

`.github/workflows/deploy.yml`：

```yaml
name: Deploy Quartz to GitHub Pages
on:
  push:
    branches: [master]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm ci
      - run: npx quartz build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/deploy-pages@v4
```

同时在 GitHub 仓库 Settings → Pages 里把 Build and deployment 的 Source 改为 **GitHub Actions**。

push 之后，GitHub Actions 自动构建部署，整个过程大约 1 分钟。

## 第二步：配置 Obsidian 写作环境

Quartz 的 `content/` 目录就是一个 Obsidian vault。打开 Obsidian → Open folder as vault → 选择 `content/` 目录。

### 推荐安装的 Obsidian 插件

**Text Generator**（[nhaouari/obsidian-textgenerator-plugin](https://github.com/nhaouari/obsidian-textgenerator-plugin)，1,908 stars）

用 Claude / GPT 辅助写作：
- 从大纲生成博文草稿
- 要点扩写成段落
- 自动生成 SEO 标题和描述

配置时填入你的 Anthropic API Key，选择 Claude 模型即可。

### 写作流程

1. 在 `content/posts/` 目录新建 markdown 文件
2. 按 `YYYY-MM-DD-slug.md` 格式命名
3. 写 frontmatter（title、date、description、tags）
4. 写正文，支持所有 Obsidian 语法
5. `git push` → 自动上线

设置 `draft: true` 的文章不会出现在站点上，适合存放未完成的草稿。

## 第三步：多平台同步

### 工具选择

调研了所有开源方案，能同时支持知乎、掘金、人人都是产品经理的只有一个：

**WechatSync**（[wechatsync/Wechatsync](https://github.com/wechatsync/Wechatsync)，5,237 stars）

支持 29+ 个平台，通过 Chrome 扩展利用浏览器登录态调用各平台 API，数据不经过第三方服务器。

### 安装

```bash
# 安装 CLI
npm install -g @wechatsync/cli
```

同时在 Chrome Web Store 搜索安装 "WechatSync 文章同步助手"扩展。

### 配置

1. 在 Chrome 中登录各平台（知乎、掘金、人人都是产品经理等）
2. WechatSync 扩展设置中开启 **"MCP Connection"**
3. 完成

### 使用

```bash
# 同步最新文章到所有平台
./scripts/sync-to-platforms.sh

# 同步指定文章
./scripts/sync-to-platforms.sh content/posts/2026-04-14-xxx.md

# 同步今天所有新文章
./scripts/sync-to-platforms.sh --all-new

# 预览不实际同步
./scripts/sync-to-platforms.sh --dry-run
```

文章会以**草稿**形式同步到各平台，你在各平台上审核确认后再发布。

### 为什么不能完全自动

WechatSync 的架构是 CLI → Chrome 扩展 → 平台 API。它必须依赖 Chrome 浏览器的登录态，因为国内平台普遍没有开放的发布 API。这是安全限制，不是技术缺陷。

好处是：你的账号密码不需要存储在任何配置文件或 CI 环境中。

## 第四步：主题定制

我用的是 Monochrome Minimal 风格，追求干净克制：

`quartz.config.ts` 中的主题配置：

```ts
typography: {
  header: { name: "Inter", weights: [400, 600] },
  body: { name: "Inter", weights: [400, 500], includeItalic: true },
  code: "JetBrains Mono",
},
colors: {
  lightMode: {
    light: "#ffffff",
    lightgray: "#f0f0f0",
    gray: "#cccccc",
    darkgray: "#333333",
    dark: "#1a1a1a",
    secondary: "#555555",    // 低调灰色链接
    tertiary: "#888888",
    highlight: "rgba(0, 0, 0, 0.04)",
  },
  // ...darkMode 同理
},
```

自定义 CSS（`quartz/styles/custom.scss`）：

```scss
// 阅读友好的内容宽度
.page > #quartz-body .center {
  max-width: 720px;
}

// 柔和的标题
h1, h2, h3, h4 {
  font-weight: 600;
  letter-spacing: -0.02em;
}

// 圆角代码块
pre {
  border: 1px solid var(--lightgray);
  border-radius: 6px;
}
```

## 启用的功能

| 功能 | 配置方式 |
|------|----------|
| Giscus 评论 | `Component.Comments({provider: "giscus"})` 基于 GitHub Discussions |
| Plausible 统计 | `analytics: {provider: "plausible"}` 隐私友好 |
| 阅读模式 | `Component.ReaderMode()` 无干扰阅读 |
| 可折叠目录 | `Plugin.TableOfContents({collapseByDefault: true})` |
| OG 社交图片 | `Plugin.CustomOgImages()` 分享时自动生成预览图 |
| Draft 过滤 | `Plugin.RemoveDrafts()` frontmatter 加 `draft: true` 即隐藏 |
| 知识图谱 | `Component.Graph()` 可视化笔记关联 |
| 双向链接 | `Component.Backlinks()` 自动生成 |

## 完整项目结构

```
bob798.github.io/
├── content/                  # Obsidian vault = 博客内容
│   ├── index.md              # 首页
│   ├── about.md              # 关于
│   └── posts/                # 文章目录
│       ├── 2026-04-14-xxx.md
│       └── ...
├── quartz/                   # Quartz 引擎（一般不用改）
│   └── styles/custom.scss    # 自定义 CSS
├── quartz.config.ts          # 站点配置
├── quartz.layout.ts          # 布局配置
├── scripts/
│   ├── sync-to-platforms.sh  # 多平台同步脚本
│   └── post-push-sync.sh    # git hook 提示脚本
└── .github/workflows/
    └── deploy.yml            # GitHub Actions 自动部署
```

## 总结

| 环节 | 工具 | 自动化程度 |
|------|------|-----------|
| 写作 | Obsidian + Text Generator | 半自动（AI 辅助） |
| 发布到博客 | git push + GitHub Actions | 全自动 |
| 多平台同步 | WechatSync CLI | 一条命令 |
| 各平台审核 | 手动 | 手动（安全需要） |

整套工具链全部开源免费，没有任何付费依赖。

## 相关链接

- 博客源码：[bob798/bob798.github.io](https://github.com/bob798/bob798.github.io)
- Quartz：[jackyzha0/quartz](https://github.com/jackyzha0/quartz)
- WechatSync：[wechatsync/Wechatsync](https://github.com/wechatsync/Wechatsync)
- Text Generator：[nhaouari/obsidian-textgenerator-plugin](https://github.com/nhaouari/obsidian-textgenerator-plugin)
