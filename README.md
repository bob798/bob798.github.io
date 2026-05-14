# Bob's Digital Garden

我的个人博客，基于 [Quartz](https://github.com/jackyzha0/quartz) 构建，部署在 GitHub Pages。

**在线访问：https://bob798.github.io**

## 技术栈

- **站点引擎**：[Quartz v4](https://quartz.jzhao.xyz/) — 专为 Obsidian 打造的静态站点生成器
- **写作工具**：Obsidian + [Text Generator](https://github.com/nhaouari/obsidian-textgenerator-plugin) AI 辅助
- **部署**：GitHub Actions → GitHub Pages（push 即自动部署）

## 功能

- 知识图谱视图（笔记关联可视化）
- 双向链接 + 反向链接
- 全文搜索
- 暗色/亮色主题
- 阅读模式
- 标签自动聚合
- RSS 订阅
- Obsidian 语法原生支持（wikilinks、callouts、embeds）

## 本地开发

```bash
npm install
npx quartz build --serve
```

浏览器访问 http://localhost:8080

## 写作流程

```
Obsidian 写笔记 → content/ 目录
   ↓
git push
   ↓
GitHub Actions 自动构建
   ↓
bob798.github.io 上线
```

## AI Handbook 知识库同步

博客自动集成 [ai-handbook](https://github.com/bob798/ai-handbook) 知识库内容。

**同步机制**：
- ai-handbook push → `repository_dispatch` → 博客自动重建
- Markdown 文件注入 frontmatter 后由 Quartz 渲染
- HTML 交互式笔记在构建后复制到 `public/`，作为静态页面直接访问

**本地同步**：
```bash
# 全量同步（md + html）
npm run sync-handbook

# 分步构建（推荐）
bash ./scripts/sync-handbook.sh          # pre-build: 同步 md
npx quartz build                          # 构建
bash ./scripts/sync-handbook.sh --html    # post-build: 复制 html
```

**CI 依赖**：ai-handbook repo 需配置 secret `BLOG_DISPATCH_TOKEN`（Fine-grained PAT，scope: bob798-blog Contents read/write）。

**自动索引生成**：`sync-handbook.sh` 会扫源仓 top-level 目录、自动生成 `content/ai-handbook/index.md` 的"知识地图"。新增一个 series 目录（含 README.md）后无需手改索引——下次 sync 时自动出现。
- 想给新 series 配中文显示名：编辑 `scripts/sync-handbook.sh` 里的 `series_display_name()` 函数加一个 case
- 想调整 series 在索引中的展示顺序：编辑同文件里的 `ORDER` 数组（未列出的会按字母序追加在末尾）

## 内容结构

```
content/
├── index.md              # 首页
├── about.md              # 关于
├── ai-handbook/          # AI 工程师知识手册（外部 repo 同步）
├── claude-code/          # 系列：Claude Code / OMC / AI 编程工作流
├── spring-ai/            # 系列：Spring AI / Java + LLM
├── dev-tools/            # 系列：Git / SSH / 工程实践
├── ai-projects/          # 系列：AI 项目实践复盘
├── archive/              # 2018-2019 老文章归档
├── <article>.md          # 独立文章（非系列，直接放根目录）
└── <article>.png         # 图片与文章同目录，相对路径引用
```

每个系列文件夹有 `index.md` 作为系列首页（简介 + 已发布清单 + 计划中清单）。

## 写作约定

### 新建文章的归类决策树

```
新文章题材是什么？
  ├─ Claude Code / OMC 相关  → claude-code/2026-MM-DD-<slug>.md
  ├─ Spring AI / Java + LLM  → spring-ai/2026-MM-DD-<slug>.md
  ├─ Git / SSH / 工程工具     → dev-tools/2026-MM-DD-<slug>.md
  ├─ 真实 AI 项目复盘         → ai-projects/2026-MM-DD-<slug>.md
  ├─ 未来计划成系列           → 新建 content/<series-name>/index.md
  └─ 独立题材（一次性）       → content/2026-MM-DD-<slug>.md
```

新增系列时，记得同步：
1. 在 `<series-name>/index.md` 写系列简介 + 计划清单
2. 在 `content/index.md` 的「系列文章」段加入口
3. 在 `quartz.layout.ts` 的 RecentNotesFolder filter 里**不需要**手动加白名单（默认包含所有非排除项）

### Frontmatter 模板

```yaml
---
title: "文章标题"
date: 2026-MM-DD
description: "一句话描述（会出现在 RSS、OG 图、列表预览）"
tags: ["主标签", "次标签"]
draft: false              # 写作中标 true，发布时改 false
---
```

### 图片放置

- **图片和 `.md` 同目录**，markdown 用相对路径 `./xxx.png` 引用
- 这是为了 WechatSync 同步到微信公众号时能自动识别并上传 CDN
- 图片数 ≤ 2：和文章 md 同级即可
- 图片数 ≥ 3：考虑独立子目录 `<series>/<post-slug>/`

### 站内链接

用 wikilink 语法 `[[<series>/<filename>|显示文字]]`（不需要 `posts/` 前缀）：

```markdown
[[claude-code/2026-04-12-claude-code-multi-agent-orchestration|Claude Code 多智能体编排]]
[[spring-ai/2026-05-11-spring-ai-advisor-explained|Spring AI Advisor]]
```

链接到系列首页用 `[[<series>/|系列名]]`（末尾斜杠指向 index.md）。

## 致谢

- [Quartz](https://github.com/jackyzha0/quartz) by jackyzha0
- 原 Jekyll 博客基于 [DONGChuan](http://dongchuan.github.io) 模板
