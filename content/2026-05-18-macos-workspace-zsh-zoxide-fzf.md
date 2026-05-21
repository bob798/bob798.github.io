---
title: "macOS 多工作区效率配置：zsh + zoxide + fzf 三件套"
date: 2026-05-18
description: "用 zsh 原生能力 + zoxide + fzf，把两个工作区（5 个项目 vs 50+ 个项目）合并成一套统一的快捷命令栈。精确跳转用 xj/ws，模糊跳转用 z，懒人选菜单用 xjp/wsp。"
tags: ["shell", "zsh", "效率", "macOS", "工作区"]
draft: true
---

## 为什么要做这个

我的开发目录长这样：

```
/Volumes/data/
├── xjspace/        # 当前主力工作区（5 个项目）
└── workspace/      # 历史沉淀工作区（50+ 个项目）
```

每天频繁切换项目，痛点很具体：

1. **目录路径太长**，敲 `cd /Volumes/data/xjspace/ai-pivot` 极伤手
2. **跨目录跳转得 cd .. 回根**，比如从 `xjspace/ai-pivot` 切到 `workspace/blog`，要么走绝对路径，要么 `cd -` 不好使
3. **50 个项目记不住名字**，靠 Tab 补全不够快
4. **同名项目区分**，比如两边都可能有 `tmp/`

我希望最终能做到：

- 知道项目名 → **1 秒到位**
- 模糊记得 → **猜也能跳对**
- 完全想不起来 → **弹菜单让我选**

下面是最终配置。

## 整体设计

按"我对目标的记忆精度"分三层：

| 精度 | 工具 | 命令示例 |
|---|---|---|
| **精确知道** | zsh 原生（CDPATH、命名目录、函数） | `xj ai-pivot` / `cd blog` |
| **模糊匹配** | zoxide | `z assist` / `z rag service` |
| **完全靠选** | fzf | `xjp` / `wsp` / `Ctrl+R` |

三层互不冲突，**叠加使用**。

## 第一层：zsh 原生快捷命令

完全不装任何东西，纯 zsh 能力。

### 1. 环境变量 + 命名目录

```zsh
# 工作区入口（换电脑改这两行就够）
export WORKSPACE="/Volumes/data/xjspace"
export BOBSPACE="/Volumes/data/workspace"

# zsh 命名目录：路径里直接用 ~xj/foo、~ws/bar
hash -d xj=$WORKSPACE
hash -d ws=$BOBSPACE
```

**`hash -d` 的神奇之处**：不仅可以用 `cd ~xj` 跳过去，**zsh 提示符里 zsh 还会自动把绝对路径反向渲染回 `~xj`**。比如你 `cd /Volumes/data/xjspace/my-assistant`，提示符显示 `~xj/my-assistant`——一眼知道在哪个工作区。

### 2. CDPATH —— `cd` 的隐藏外挂

```zsh
# 从任何位置 `cd <项目名>` 都能命中
export CDPATH=".:$WORKSPACE:$BOBSPACE:$HOME"
```

效果：

```bash
cd /tmp
cd ai-pivot     # → /Volumes/data/xjspace/ai-pivot
cd blog         # → /Volumes/data/workspace/blog
```

**关键**：前导 `.` 必须有，否则会用 CDPATH 里的目录覆盖本地同名目录优先级，踩坑警告。

查找顺序就是 CDPATH 里的顺序，xjspace 在前所以小工作区优先（同名时主力项目胜出）。

### 3. 函数家族（带 Tab 补全）

```zsh
# --- xjspace 家族 ---
xj()  { cd "$WORKSPACE/${1:-}"; }      # xj / xj <项目>
xjl() { ls -1 "$WORKSPACE"; }
xjf() { open "$WORKSPACE/${1:-}"; }    # Finder
xjo() { code "$WORKSPACE/${1:-.}"; }   # VS Code
xji() { idea "$WORKSPACE/${1:-.}"; }   # IDEA

# --- workspace 家族 ---
ws()  { cd "$BOBSPACE/${1:-}"; }
wsl() { ls -1 "$BOBSPACE"; }
wsf() { open "$BOBSPACE/${1:-}"; }
wso() { code "$BOBSPACE/${1:-.}"; }
wsi() { idea "$BOBSPACE/${1:-.}"; }

# Tab 补全：按 Tab 时候列出工作区内的项目名
_xj_projects() { local -a p; p=($WORKSPACE/*(/N:t)); _describe 'project' p; }
_ws_projects() { local -a p; p=($BOBSPACE/*(/N:t));  _describe 'project' p; }
compdef _xj_projects xj xjo xji xjf
compdef _ws_projects ws wso wsi wsf
```

`${1:-}` 是 zsh 的"参数缺省值"——没传参数就空串，所以 `xj` 单独跑会跳工作区根，`xj ai-pivot` 进子项目。

`*(/N:t)` 是 zsh glob 修饰符：
- `/` 只匹配目录
- `N` 无匹配时返回空（避免报错）
- `:t` 取 basename

## 第二层：zoxide —— 智能 `cd`

> 一句话：zoxide 是 `cd` 的"频率+最近"加强版。你越常去的目录，越容易被命中。

### 安装

```bash
brew install zoxide
echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
```

### 用法

```bash
z assist          # 跳到含 "assist" 的最高分目录（→ my-assistant）
z pivot           # → ai-pivot
z rag service     # 多关键词，都要命中（→ rag-customer-service）
z claude rag      # → claude-develop-rag

zi                # 弹 fzf 菜单从历史目录选（不放心 z 跳错时用）
zi claude         # 只在含 claude 的目录里选
```

### 三个核心规则

1. **只能跳你 cd 进去过的目录**——zoxide 不会扫盘，需要"学习"
2. **多关键词必须**全部**命中**，最后一个还要匹配路径末段（basename）
3. **分数随频率+最近**衰减，老不去的目录会自动让位

### 一次性预热所有项目

新建工作区时，把所有项目灌进去一次，第一次 `z` 就能用：

```bash
for d in "$WORKSPACE"/*/ "$BOBSPACE"/*/; do
  [ -d "$d" ] && zoxide add "$d"
done
```

### 看 zoxide 都记了啥

```bash
zoxide query -ls          # 全部，按 score 倒序
zoxide query -ls claude   # 只看含 claude 的
zoxide remove /old/path   # 删过期记录
```

## 第三层：fzf —— 模糊选择器

> 一句话：fzf 是 Unix 哲学的极致——任何列表丢给它，弹出可输入过滤的交互菜单。

### 安装

```bash
brew install fzf

# 加到 .zshrc
source /usr/local/opt/fzf/shell/key-bindings.zsh
source /usr/local/opt/fzf/shell/completion.zsh
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'
```

### 全局键位（任何时候）

| 键位 | 作用 |
|---|---|
| `Ctrl+R` | **模糊搜历史命令** —— 用过就回不去 |
| `Ctrl+T` | 模糊选当前目录下文件，路径自动贴到命令行 |
| `Alt+C`  | 模糊 cd 到当前目录的子目录 |

`Ctrl+R` 是最值得养成的习惯。在 fzf 菜单里你可以：

- 直接输关键词模糊过滤（不区分顺序、大小写）
- `Ctrl+J/K` 上下移动
- 回车选中
- `Esc` 取消

### 工作区项目选择器（自定义）

```zsh
xjp()  { local p=$(ls "$WORKSPACE" | fzf --prompt="xj> ") && cd "$WORKSPACE/$p"; }
wsp()  { local p=$(ls "$BOBSPACE"  | fzf --prompt="ws> ") && cd "$BOBSPACE/$p"; }
xjpo() { local p=$(ls "$WORKSPACE" | fzf --prompt="xj→code> ") && code "$WORKSPACE/$p"; }
wspo() { local p=$(ls "$BOBSPACE"  | fzf --prompt="ws→code> ") && code "$BOBSPACE/$p"; }
```

用法：

```bash
xjp        # 弹菜单选 xjspace 项目 → cd
wsp        # 弹菜单选 workspace 项目 → cd（50 个项目时神器）
wspo       # 选完直接 VS Code 打开
```

输入 `bkc` 能命中 `bookcircle`、输入 `rdg` 能命中 `reading-club`——fzf 的子序列匹配很宽松。

## 完整命令矩阵

| 场景 | 命令 | 示例 |
|---|---|---|
| **完全记得名字** | `cd <项目>` | `cd ai-pivot`（依赖 CDPATH） |
| 进工作区根 | `xj` / `ws` | `ws` |
| 进子项目 | `xj <名>` / `ws <名>` | `xj ai-pivot` |
| 列出项目 | `xjl` / `wsl` | `xjl` |
| VS Code 打开 | `xjo` / `wso` | `xjo my-assistant` |
| IDEA 打开 | `xji` / `wsi` | `wsi blog` |
| Finder 打开 | `xjf` / `wsf` | `xjf` |
| 命名目录路径 | `~xj/...` / `~ws/...` | `vim ~xj/ai-pivot/README.md` |
| **模糊匹配** | `z <部分名>` | `z assist` |
| 模糊+菜单 | `zi <部分名>` | `zi claude` |
| **菜单选择** | `xjp` / `wsp` | `wsp` |
| 菜单+打开 | `xjpo` / `wspo` | `wspo` |
| 历史命令 | `Ctrl+R` | 输关键词过滤 |
| 当前目录选文件 | `Ctrl+T` | `vim` + `Ctrl+T` |

## 实战场景

**场景 1：早上开工**
```bash
xjp                  # 菜单选今天要搞哪个项目
# 选中 my-assistant 后
code .               # 当前目录已经是项目根
```

**场景 2：突然想起昨天那个项目**
```bash
z assist             # 直接跳过去，zoxide 记得你最近的偏好
```

**场景 3：跨工作区临时切**
```bash
# 现在在 xjspace/ai-pivot 调试
cd blog              # CDPATH 命中 workspace/blog
# 看完想回来
cd -                 # zsh 原生：回到上一个目录
```

**场景 4：复现昨天那条复杂命令**
```bash
Ctrl+R
# 输 "kubectl logs"，模糊匹配历史里所有 kubectl + logs 的组合
```

## 几个踩坑提醒

### ❌ CDPATH 忘了前导 `.`

```zsh
export CDPATH="$WORKSPACE:$HOME"     # 错！本地同名目录会被覆盖
export CDPATH=".:$WORKSPACE:$HOME"   # 对
```

### ❌ 重命名 `hash -d` 别名后旧路径失效

我一开始把 xjspace 命名成 `~ws`，后来加 BOBSPACE 时发现 workspace 字面叫 "workspace"，被迫把 xjspace 改名 `~xj`。**如果之前在脚本里用过 `~ws` 指 xjspace，要全局替换。**

教训：**命名直接对应目录的字面名字**，不要图省事用 WORKSPACE 之类的语义名。

### ❌ zoxide 第一次跳不到陌生目录

zoxide 不扫盘。新增工作区一定要预热一次（见上文脚本），或者每个新项目第一次手动 cd 进去。

### ❌ fzf 全局键位 Ctrl+T 在某些 tmux 配置里被吃掉

如果 `Ctrl+T` 没反应，检查 tmux 的 prefix 是不是 `C-t`，改成别的（比如 `C-a` 或 `C-Space`）。

## 完整 .zshrc 配置块

直接抄走（macOS / zsh / 假设 brew 装在 `/usr/local`）：

```zsh
# ===== 工作区入口 =====
export WORKSPACE="/Volumes/data/xjspace"
export BOBSPACE="/Volumes/data/workspace"

# ===== zsh 原生快捷 =====
hash -d xj=$WORKSPACE
hash -d ws=$BOBSPACE
export CDPATH=".:$WORKSPACE:$BOBSPACE:$HOME"

# 跳转/列出/打开
xj()  { cd "$WORKSPACE/${1:-}"; }
xjl() { ls -1 "$WORKSPACE"; }
xjf() { open "$WORKSPACE/${1:-}"; }
xjo() { code "$WORKSPACE/${1:-.}"; }
xji() { idea "$WORKSPACE/${1:-.}"; }

ws()  { cd "$BOBSPACE/${1:-}"; }
wsl() { ls -1 "$BOBSPACE"; }
wsf() { open "$BOBSPACE/${1:-}"; }
wso() { code "$BOBSPACE/${1:-.}"; }
wsi() { idea "$BOBSPACE/${1:-.}"; }

# Tab 补全
_xj_projects() { local -a p; p=($WORKSPACE/*(/N:t)); _describe 'project' p; }
_ws_projects() { local -a p; p=($BOBSPACE/*(/N:t));  _describe 'project' p; }
compdef _xj_projects xj xjo xji xjf
compdef _ws_projects ws wso wsi wsf

# ===== zoxide：智能 cd =====
eval "$(zoxide init zsh)"

# ===== fzf：模糊选择器 =====
source /usr/local/opt/fzf/shell/key-bindings.zsh
source /usr/local/opt/fzf/shell/completion.zsh
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'

# fzf 工作区项目选择器
xjp()  { local p=$(ls "$WORKSPACE" | fzf --prompt="xj> ") && cd "$WORKSPACE/$p"; }
wsp()  { local p=$(ls "$BOBSPACE"  | fzf --prompt="ws> ") && cd "$BOBSPACE/$p"; }
xjpo() { local p=$(ls "$WORKSPACE" | fzf --prompt="xj→code> ") && code "$WORKSPACE/$p"; }
wspo() { local p=$(ls "$BOBSPACE"  | fzf --prompt="ws→code> ") && code "$BOBSPACE/$p"; }
```

需要先执行：

```bash
brew install zoxide fzf

# 预热 zoxide（不预热的话第一次 z 跳不到工作区项目）
for d in "$WORKSPACE"/*/ "$BOBSPACE"/*/; do
  [ -d "$d" ] && zoxide add "$d"
done

# 重开终端窗口（或 source ~/.zshrc）
```

## 后续可加的扩展

按需叠加，每个都是独立模块：

1. **`xjg <pattern>` —— 在当前工作区跨项目 grep**
   `rg` + `--type` 过滤，比 IDE 全局搜还快
2. **`xjt <项目>` —— 切到项目并打开 tmux 会话**
   一个项目 = 一个 tmux 会话，断网回家继续
3. **`gh-fzf` —— GitHub PR 列表用 fzf 选**
   `gh pr list` + fzf + `gh pr checkout`
4. **`f` —— fasd 风格的文件级 frecency**
   不只是目录，连最近编辑过的文件也能 `f resume` 跳到

## 设计哲学

回头看，三层结构的本质是**让工具匹配你的认知精度**：

- 精度高的时候，**别让工具拖累**（直接 `cd ai-pivot`，0 思考成本）
- 精度模糊的时候，**别强迫精确**（`z assist` 让工具补全你的记忆）
- 完全没精度的时候，**别假装记得**（`xjp` 弹菜单，承认自己忘了）

很多人卡在只用 `cd` 或者只装 zoxide。但单一工具应对不了所有精度区间——叠加才舒服。

---

> 配置完整跑在 macOS 14 + zsh 5.9 + Prezto。Linux 应该一样能用，只是 brew 路径需要改成 `/home/linuxbrew/.linuxbrew/opt/fzf/` 或 apt 装的 `/usr/share/doc/fzf/examples/`。
