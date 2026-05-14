---
title: "SSH Key 轮换：本地换了新 key，服务器旧 key 怎么办？"
date: 2026-05-12
description: "本地更新 SSH key 后，服务器上的旧公钥要不要删、怎么删，以及多 key 共存的实操指南"
tags: ["ssh", "git", "security", "devops", "blog"]
draft: false
---

> 换了新电脑生成了新 SSH key，旧 key 留在服务器上是安全隐患还是无所谓？这篇把判断逻辑和操作步骤一次说清楚。

## 先看结论

**功能上不需要删，安全上建议删。**

服务器端的 `authorized_keys` 是个**白名单**——任何一把对得上私钥的公钥都能登录，多把可以并存。所以：

- 旧 key 留着 → **不影响**新 key 工作
- 旧 key 留着 → **旧私钥还能登录**

第二点就是潜在的安全风险所在。

---

## 决策表：到底删不删

| 旧私钥的去向 | 旧公钥要不要删 | 原因 |
|------------|---------------|------|
| 还在用（多机协作、自己另一台电脑） | ❌ 别删 | 删了那台机器就登不上 |
| 旧电脑卖了 / 换新电脑了 | ✅ 必须删 | 否则旧机器持有人能用旧私钥访问你账号 |
| 旧私钥被泄露 / 疑似泄露 | ✅ 立刻删 | 安全事件，删 + 改密码 |
| 单纯重新生成了一把（旧的还在本机） | ⚠️ 看情况 | 不再用就删，过渡期可以并存 |

---

## 操作步骤：怎么删

### 场景 ①：Gitea / GitLab / GitHub 等代码托管平台

**用网页删，不要去碰服务器文件**。这些平台用数据库管理 key，再同步到 `authorized_keys`，直接改文件会被下次同步覆盖。

#### Gitea

```
头像 → Settings → SSH / GPG Keys
   → 找到要删的 key（核对指纹/备注）
   → 点右侧 [Delete]
```

#### GitLab

```
头像 → Edit profile → SSH Keys
   → 找到要删的 key
   → 点 [Remove] 或垃圾桶图标
```

#### GitHub

```
头像 → Settings → SSH and GPG keys
   → Authentication keys 列表
   → 点 [Delete] 按钮
```

#### 对指纹避免误删

本地查指纹：

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
# SHA256:xxxxxxxxx
```

到网页对照 "Fingerprint" 列，删除对应那一行。

### 场景 ②：纯 SSH 服务器（直接 ssh 访问，没有托管平台）

直接编辑目标用户的 `authorized_keys`：

```bash
# 登录到服务器
ssh user@server

# 编辑文件
vi ~/.ssh/authorized_keys
# 找到要删的那一行（以 ssh-ed25519/ssh-rsa 开头），整行删除

# 权限不能动
chmod 600 ~/.ssh/authorized_keys
```

**怎么定位是哪一行**：每行末尾的 comment 一般是 `user@hostname`，能区分。或者按指纹对照：

```bash
# 服务器上查每行公钥的指纹
ssh-keygen -lf ~/.ssh/authorized_keys
```

#### 一键删除（脚本化）

如果你知道公钥末尾的注释（比如 `bob@old-laptop`）：

```bash
# 删除注释含 "old-laptop" 的整行，自动备份
sed -i.bak '/old-laptop/d' ~/.ssh/authorized_keys
```

确认没问题后可以删掉 `~/.ssh/authorized_keys.bak`。

---

## 启用新 key 的完整流程

不管删不删旧的，**新 key 要工作的前提是公钥已上传到服务器**：

```bash
# 1. 取新公钥
cat ~/.ssh/id_ed25519.pub

# 2. 到 git 服务器（Gitea/GitLab）SSH Keys 页面：
#    - 添加新公钥
#    - 顺手删除不用的旧公钥（页面上对照指纹）

# 3. 验证连通
ssh -T git@git.rd.local
```

成功的话会看到类似：

```
Hi bob! You've successfully authenticated, but Gitea does not provide shell access.
```

---

## 验证删除是否生效

从那台**持有旧私钥**的机器试登录：

```bash
ssh -T git@git.rd.local
# 期望：Permission denied (publickey)
```

如果还能登上去，说明：

- 删错了（实际删的是别的 key）
- 或者旧 key 在多个账号下都加过

---

## 一个常被忽视的坑：本地多 key 时

如果本机同时存有旧的和新的私钥文件，SSH 默认会**按顺序都试一遍**。某些服务器对单次连接有"最多尝试 N 把 key 就拒绝"的限制（`MaxAuthTries`，默认 6），多 key 容易触发：

```
Received disconnect from ...: Too many authentication failures
```

### 解法：在 `~/.ssh/config` 显式指定

```
Host git.rd.local
    HostName git.rd.local
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

`IdentitiesOnly yes` 是关键——告诉 SSH **只用我指定的这一把，别的别试**。

---

## 关于"key 轮换"的最佳实践

定期换 key 不是必须，但这些场景一定要换：

1. **私钥可能泄露**（电脑被偷、误传到公开仓库、共享给他人）
2. **离开某个组织**（清理在前公司服务器上的 key）
3. **设备退役**（卖电脑、换电脑）
4. **算法升级**（比如从 RSA 2048 换 Ed25519）

轮换的标准动作：

```
新机器：
  1. 生成新 key:           ssh-keygen -t ed25519
  2. 上传新公钥到服务器
  3. 验证可用:             ssh -T git@host

老机器（要退役）：
  4. 从服务器删除旧公钥
  5. 验证旧 key 已失效:    ssh -T git@host  # 应被拒绝
  6. 销毁旧私钥:           shred -u ~/.ssh/id_ed25519  # Linux
                          # 或 rm -P ~/.ssh/id_ed25519  # macOS
```

---

## 一句话总结

- **新公钥必须上传** → 新 key 才能用
- **旧公钥**：如果对应私钥不再持有，**删掉**；如果还在别处用，**留着**
- **多 key 共存**：用 `~/.ssh/config` + `IdentitiesOnly yes` 防止 SSH 乱试

---

*相关阅读：[Git Clone 踩坑记：SSH 公钥认证失败到 HTTPS 证书报错的全流程排查](2026-05-11-git-clone-ssh-https-debug.md)*
