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

## 内容结构

```
content/
├── index.md          # 首页
├── about.md          # 关于
└── posts/            # 博客文章
    ├── 2026-04-14-speakeasy-ai-english-tutor.md
    ├── 2026-04-13-ai-handbook-learning-path.md
    ├── 2026-04-12-claude-code-multi-agent-orchestration.md
    └── ...
```

## 致谢

- [Quartz](https://github.com/jackyzha0/quartz) by jackyzha0
- 原 Jekyll 博客基于 [DONGChuan](http://dongchuan.github.io) 模板
