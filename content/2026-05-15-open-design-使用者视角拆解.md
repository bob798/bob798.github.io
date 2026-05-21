---
title: "Open Design 使用者视角拆解：开源版 Claude Design 值不值得装"
date: 2026-05-15
description: "从使用者角度拆解 nexu-io/open-design：它真正卖的不是 AI 设计师，而是 prompt stack 这一层中间件。附桌面端 vs 网页端选型 + 下载数据揭示的真实用户画像。"
tags: ["AI", "产品拆解", "开源", "设计工具", "Claude"]
draft: true
---

> 仓库地址：[github.com/nexu-io/open-design](https://github.com/nexu-io/open-design)

## 一句话定位

> 把你**本地已经装好的 coding agent CLI**（Claude Code / Codex / Cursor / Gemini …）变成「设计师」，本地跑、自带 31 个技能 + 72 套设计系统，开源免费替代 Anthropic 闭源的 Claude Design。

---

## 1. 使用者到底是谁、解决什么问题

| 维度 | 内容 |
|---|---|
| **目标用户** | ① 已经付费用 Claude Code / Codex 等 CLI 的开发者 / 设计工程师；② 想用 LLM 做"看得见的东西"（落地页、PPT、邮件、原型图）但被 Claude Design 的付费墙挡住的人；③ 企业内部 / 数据敏感场景，不能把品牌资料发到云端的团队 |
| **替代方案** | Claude Design（闭源、订阅、只跑 Anthropic）/ Lovable / v0 / Bolt（云端、按 token 收费、模型锁定）/ 手写 prompt 让 Claude 输出 HTML（无 skill、无设计系统、无沙箱预览） |
| **核心痛点** | 这些替代方案要么**锁模型**、要么**锁云端**、要么**没有"设计师工艺"**——LLM 直接 freestyle 出来的东西多半是 AI slop |

**这是真需求还是伪需求？** 真需求，但**狭义**——它假设你已经为 CLI agent 付费了。如果你没装 Claude Code 也没 API key，这个产品对你价值很低（虽然给了 BYOK proxy 兜底）。

---

## 2. 用户实际怎么用（关键路径）

```
1. pnpm tools-dev            ← 一条命令起本地 daemon + web
2. 选 Skill（31 选 1）        ← saas-landing / mobile-app / ppt / 邮件…
3. 选 Design System（72 选 1）← Linear / Stripe / Vercel / 小红书…
4. 写 brief                   ← "给我一个种子轮路演 PPT"
5. ★ 强制弹「discovery 表单」← 30 秒勾选：受众、语气、品牌、规模
6. 如无品牌 → 弹「方向选择器」← 5 种流派 1 选 1
7. 实时看 TodoWrite 计划流动  ← 可随时中断重导
8. 沙箱 iframe 预览 artifact  ← 导出 HTML / PDF / PPTX / MP4
```

**最值得说的两个体验设计**：

- **第 5 步的「先填表再画图」** 是整个产品的灵魂。它把"AI 乱跑→用户来回纠正"的循环，前置成 30 秒的单选题。这是从 [`huashu-design`](https://github.com/alchaincyf/huashu-design) 偷来的"Junior Designer 模式"——也是它输出不像 AI slop 的根本原因。
- **第 7 步 daemon 给 agent 真实文件系统**。agent 能 `Read` skill 的 `template.html`、`grep` 你的 CSS 拿色值、写 `brand-spec.md`——它在你电脑上、用你装的 CLI、操作你项目下的真实文件夹（`.od/projects/<id>/`）。这是它和云端 SaaS 的根本分野。

---

## 3. 商业模式（用户视角的"代价"）

| 项目 | 真相 |
|---|---|
| **License** | Apache-2.0，免费 |
| **隐性成本** | 你**已经在付**的那个 CLI（Claude Code Max 订阅 / OpenAI API / Cursor 等）才是真正的计费方 |
| **变现路径** | 仓库里看不到明显商业化，挂了 `open-design.ai` 域名 + Discord + 关联组织 `nexu-io`——典型「开源圈用户 + 公司后置变现」的姿势（很可能后续做托管版 / 企业版 / 模型路由计费） |

**对使用者意味着**：现在是白嫖窗口期；但要警惕项目活跃度——它**强依赖上游 CLI 不变**，任何一家（Claude Code、Codex）改 stdio 协议，adapter 就要跟着改。

---

## 4. 它和最像的对手怎么比

**最直接的对手**：[`OpenCoworkAI/open-codesign`](https://github.com/OpenCoworkAI/open-codesign)（同样是 Claude Design 开源平替，作者自己 README 里也写明了"我们的最近邻"）。

| 维度 | open-design (本项目) | open-codesign |
|---|---|---|
| 形态 | **Web + 本地 daemon**（也可打 Electron） | 桌面 Electron App |
| Agent | 扫 PATH 用你**已有的 16 种 CLI** | 内嵌 `pi-ai` |
| 设计系统 | **72+ 套**预置 Markdown | 较少 |
| Skill 体系 | 31 个、按 SKILL.md 协议、加文件夹即生效 | 较弱 |
| 路线分歧 | "你已经有 agent 了，我只是把它接入设计循环" | "我打包一个完整桌面应用给你" |

**它的真正护城河不是代码，而是 prompt stack 和素材库**——`apps/daemon/src/prompts/discovery.ts`（5 学派 × 20 设计哲学）+ 72 套 `DESIGN.md` + 31 个 skill 模板。这些是慢功夫，复制需要时间。

---

## 5. 使用者要警惕什么

1. **学习曲线被低估**：表面"3 条命令"，但要装 pnpm、Node、再装至少一个 CLI、再 BYOK——对非工程师用户门槛偏高。
2. **CLI 协议变更风险**：16 个 adapter 是技术债，上游任何一家小版本改动都可能让某条路径炸掉。
3. **"开源"≠"免费"**：真正贵的是底下 LLM token；如果你的 brief 让 agent 做 50 步 TodoWrite，你的 Claude Code 用量会肉眼可见地涨。
4. **审美天花板被 design system 锚定**：72 套已经很多，但你想要的"小众杂志风"不在库里时，agent 表现会断崖式下降——它的好看是**借来的**，不是涌现的。

---

## 6. 桌面端到底是什么、要不要装

### 数据：这不是 PPT 上的"未来规划"

最新版本 **v0.7.0**（2026-05-13 发布），覆盖 macOS arm64 / x64 + Windows x64，**6 天迭代一个小版本**。把最近三个版本的 GitHub Release 下载量拉出来：

| 版本 | mac arm64 .dmg | mac x64 .dmg | Windows .exe | 发布日期 |
|---|---:|---:|---:|---|
| v0.7.0 | 6,009 | 894 | 10,233 | 2026-05-13 |
| v0.6.0 | 10,194 | — | **36,902** | 2026-05-09 |
| v0.5.0 | 6,737 | — | 11,291 | 2026-05-07 |

两个反直觉信号：

1. **Windows 下载量是 macOS 的 1.5–4 倍**——和典型设计工具（Figma / Sketch 用户 mac 占绝对多数）完全相反。说明实际用户画像是「**AI 折腾党 / 中国市场开发者**」，不是设计师。
2. **6 天一个小版本**：v0.5 → v0.7 三个版本只隔了 6 天。这种节奏要么是产品强势期、要么是 schema 还在剧烈变形——对生产环境用户都是双刃剑。

### 桌面端 vs 网页端：底层是同一套代码

底层都是 daemon + web。Electron 只是套了个壳，但壳里塞了一个 **sidecar IPC**：`STATUS / EVAL / SCREENSHOT / CONSOLE / CLICK / SHUTDOWN`。

这个 IPC 表是关键——它不是给"用户点按钮"用的，是给**外部脚本远程驱动这个桌面 App** 用的（典型场景：agent 截图自己刚画完的设计、自动点一下"导出"、把控制台错误读回去）。也就是说：

> 桌面端的真正卖点不是"双击图标好看"，而是"让 agent 能反向操作这个 App"。它在为「AI 跑完一轮，自己截图自检、自己点导出」铺路。

| 维度 | 网页端 (`pnpm tools-dev`) | 桌面端 (.dmg / .exe) |
|---|---|---|
| 上手成本 | 装 pnpm + Node 22+ + 至少一个 agent CLI | 双击安装，仍要装一个 agent CLI |
| 包体积 | 仓库小，跑起来轻 | **200 MB 左右**（Electron 税） |
| 升级 | `git pull` | 自动更新（看到 `latest-mac.yml` / `latest.yml`，走 electron-updater） |
| 进阶能力 | 没 IPC | 自动化、E2E、未来 agent 自驱 UI |
| 隐私 | 本地 | 本地（壳不改变这件事） |

**怎么选**：

- 不打算改它的代码、不在意 200MB → **桌面端是更合理的入口**。
- 要研究 prompt stack / 加 skill → **仓库版才是真本体**。

---

## 四条核心洞察

> 💡 **洞察 1 ｜ 真正的产品不是"AI 设计师"，而是 prompt stack 这一层中间件。**
> 它做的事是：把"你已经付费的 LLM CLI"+"开源设计哲学"+"品牌资产库"+"沙箱预览"粘成一条流水线。AI 是别人的，护城河是粘合剂。

> 💡 **洞察 2 ｜ 最值得抄的设计决策：先填表，再生成。**
> `RULE 1: 任何新 brief 先弹 question-form`——把 LLM 时代普遍存在的"来回拉扯"成本，从对话轮次转移到 30 秒单选题。任何 AI 产品都该思考这条。

> 💡 **洞察 3 ｜ 最大变量是 Anthropic 自己。**
> 如果 Claude Design 哪天开放 self-host / 降价 / 开源 skill 协议，这类"开源平替"立刻失去最大叙事。反之，如果 Anthropic 继续闭源 + 抬价，它的窗口会越来越大。它的命运不在自己手里，在 Anthropic 的产品策略里。

> 💡 **洞察 4 ｜ 真正在用这个产品的人，是 Windows 上的 AI 折腾党，不是设计师。**
> 36k Windows / 10k macOS 这种比例，对一款"设计工具"是异常的——它泄露了产品的**真实生态位**：这不是 Figma 的对手，是面向"装了 Claude Code / Codex 的 AI 早期采用者"的玩具兼利器。这也解释了为什么它敢假设"用户已经有一个 CLI"——它的用户群本来就是。

---

**如果你是来"学习借鉴"**：直接读 `apps/daemon/src/prompts/discovery.ts` 和 `directions.ts`——那是这个产品最值钱的两个文件，比仓库里所有 React 代码加起来都重要。
