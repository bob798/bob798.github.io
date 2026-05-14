---
title: "Git Clone 踩坑记：SSH 公钥认证失败到 HTTPS 证书报错的全流程排查"
date: 2026-05-11
description: "从 Permission denied (publickey) 到 unable to get local issuer certificate，一次内网 git clone 的全链路排查与原理梳理"
tags: ["git", "ssh", "tls", "devops", "blog"]
draft: false
---

> 公司内网拉一个仓库，按理说三秒钟的事，结果连环踩坑。这篇把整个排查过程和背后的原理梳理清楚。

## 缘起

```bash
$ git clone git@git.rd.local:ai/ai-pivot.git
正克隆到 'ai-pivot'...
git@git.rd.local's password:
Permission denied, please try again.
...
git@git.rd.local: Permission denied (publickey,password).
致命错误：无法读取远程仓库。
```

明明已经配置了 SSH key，为什么还在问密码？换 HTTPS 又跳出证书错误？

---

## 一、为什么 SSH 还在问密码？

第一个困惑：明明配了 key，为什么会弹密码框？

服务器在握手时告诉客户端：

```
debug1: Authentications that can continue: publickey,password
```

**SSH 客户端的策略是**：先试 publickey，**失败了自动降级到下一个方法**——这里就是 password。

所以"被问密码"不是必须用密码，而是公钥认证没过关被踢下来了。

### 强制只走公钥（让真正的失败原因暴露出来）

编辑 `~/.ssh/config`：

```
Host git.rd.local
    HostName git.rd.local
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    PreferredAuthentications publickey
    PasswordAuthentication no
    KbdInteractiveAuthentication no
```

权限要对：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config ~/.ssh/id_ed25519
```

这样配完，公钥不通**直接报错退出**，不会再被密码框打断，定位会快很多。

---

## 二、解读 `ssh -vT` 调试日志

最有用的命令是带 verbose 的连接测试：

```bash
ssh -vT git@git.rd.local
```

关键日志逐句对照：

```
debug1: get_agent_identities: agent returned 1 keys
   ↑ ssh-agent 里加载了 1 把 key

debug1: Will attempt key: ~/.ssh/id_ed25519 ED25519 SHA256:uptz... explicit
   ↑ 准备使用这把（"explicit" = -i 显式指定）

debug1: Offering public key: ~/.ssh/id_ed25519 ...
   ↑ 把公钥指纹递给服务器：你认识这把吗？

debug1: Authentications that can continue: publickey,password
   ↑ 服务器回复："不认识，换一种"
   ↑ 这就是被拒的瞬间

debug1: No more authentication methods to try.
   ↑ 客户端别的 key 都试完了，放弃
```

**判断模板**：

| 现象 | 含义 |
|------|------|
| 没出现 `Offering public key` | 本地私钥被跳过（多半权限不对） |
| 出现 `Offering` 但 `can continue` 又被踢回 | 服务器不认识这把公钥 |
| 出现 `Authenticated to ...` | 认证成功 |

---

## 三、SSH 公钥认证完整流程

理解流程才知道每一步可能出什么问题。

```
客户端 (你)                              服务器 (git.rd.local)
   │                                          │
   │ ─────── 1. TCP 握手 (端口 22) ─────────► │
   │                                          │
   │ ◄────── 2. 协议版本协商 ─────────────── │
   │                                          │
   │ ─────── 3. 密钥交换 (KEX) ─────────────► │
   │   ▸ 选算法 (curve25519, aes256-gcm...)   │
   │   ▸ ECDH 协商出会话密钥                  │
   │   ▸ 服务器发送 host key 证明身份         │
   │   ▸ 客户端用 known_hosts 校验 host key   │
   │ ◄══════ 加密通道建立完成 ══════════════ │
   │                                          │
   │ ─────── 4. 用户认证 (公钥认证) ────────► │  ← 关键
```

### 第 4 步展开：服务器是怎么认识你 key 的

```
客户端                                    服务器
   │                                          │
   │ "我是 git，想用 publickey 登录"          │
   │ ────────────────────────────────────────►│
   │                                          │
   │ "我有这把公钥，认识吗？" (只发指纹)      │
   │ ────────────────────────────────────────►│
   │                                          │  查 ~git/.ssh/authorized_keys
   │                                          │  逐行比对公钥本体
   │                                          │
   │ ◄──── "认识，给你一段随机数，签一下"      │
   │                                          │
   │ 用私钥对 [随机数 + 会话ID] 做签名        │
   │ ────────────────────────────────────────►│
   │                                          │  用对应公钥验签
   │                                          │
   │ ◄──── "签名对，登录成功"                  │
   │                                          │
   │ ─── 起 Git 通道，跑 git-upload-pack ───► │
```

**关键点**：私钥永远不离开本机，只用来签名。服务器只验证签名，反推不出私钥。

### 客户端怎么挑用哪把 key

按优先级：

1. `ssh-add` 加到 ssh-agent 的 key
2. `~/.ssh/config` 里 `IdentityFile` 显式指定的
3. 默认文件名：`id_ed25519`、`id_ecdsa`、`id_rsa`

### 服务器怎么决定认不认

逐行读 `/home/git/.ssh/authorized_keys`：

```
ssh-ed25519 AAAAC3Nza...XYZ comment1
ssh-ed25519 AAAAC3Nza...ABC comment2
```

**只比对中间那段 base64 公钥本体**，注释、邮箱全部忽略。

---

## 四、几个常被误解的概念

### 1. SSH key 末尾的邮箱不影响认证

```
ssh-ed25519 AAAAC3Nza...XYZ bob@old-laptop
                            └────┬────┘
                              这只是注释
```

改成 `alice@mars` 也能登录，删掉也能登录。SSH 协议根本不解析它。

例外：少数企业版 GitLab 配置了"key 注释邮箱必须等于账号邮箱"——这是平台业务规则，不是 SSH 协议。

### 2. SSH 用的是"密钥对"，不是"证书"

| 项 | 密钥对 (key pair) | 证书 (certificate) |
|----|-------------------|-------------------|
| 组成 | 一对纯数学关系的公私钥 | 公钥 + CA 签发的元信息 |
| 有效期 | 无 | 有 |
| 签发方 | 自己生成 | CA |
| SSH 默认用 | ✅ | ❌（支持但少用） |
| HTTPS 用 | ❌ | ✅ X.509 证书 |

你日常的 `id_ed25519` / `id_ed25519.pub` 是**密钥对**。

### 3. SSH 和 HTTPS 是两条完全独立的路

| 协议 | 端口 | 加密凭证 | 受 TLS 证书影响吗 |
|------|------|---------|-----------------|
| HTTPS | 443 | TLS 证书 | ✅ |
| SSH | 22 | SSH key | ❌ |

**所以"内部 CA 证书没拿到" 完全不影响 SSH clone。**

---

## 五、SSH 认证失败的排查 checklist

按概率从高到低排：

### ① 私钥权限不对（SSH 会静默跳过）

```bash
ls -l ~/.ssh/id_ed25519
# 必须是 -rw-------
chmod 600 ~/.ssh/id_ed25519
chmod 700 ~/.ssh
```

### ② 服务器上注册的不是当前这把 key

对指纹：

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
# SHA256:xxxxxx
```

到 git 服务器（Gitea/GitLab）SSH Keys 页面对照每一条 key 的指纹。

### ③ key 同步延迟/损坏（自建实例常见 bug）

Gitea/GitLab 是后台把网页加的 key 写入 `git` 用户的 `~/.ssh/authorized_keys`。**网页能看到不代表文件里有**。

让管理员在服务器上看：

```bash
sudo grep "公钥末尾几位" /home/git/.ssh/authorized_keys
```

最快的修复手段：**网页把 key 删了重新添加一次**，强制刷新。

### ④ 用户名/端口不对

很多内网改了端口：

```bash
ssh -vT -p 2222 git@git.rd.local
# 或在 ~/.ssh/config 里加 Port 2222
```

### ⑤ 终极手段：让管理员看 sshd 日志

```bash
# 服务器侧
sudo journalctl -u sshd -f
# 或 sudo tail -f /var/log/auth.log
```

你这边发起 `ssh -T git@git.rd.local`，日志会写明白拒因：

- `Failed publickey for git ... key not allowed`
- `Connection closed by authenticating user git`

这是定位的核武器，比客户端 verbose 信息多得多。

---

## 六、HTTPS 那条路的证书问题

绕到 HTTPS 又遇到：

```
SSL certificate problem: unable to get local issuer certificate
```

**含义**：内网 git 用的是公司自己 CA 签发的证书，你系统信任库里没有这个内部 CA 的根证书，git 不知道签发方是谁，拒绝建立连接。

```
公网证书 (GitHub 等)
   ↓ 由 公共 CA 签发 (Let's Encrypt 等)
   ↓ 这些 CA 根证书已预装在 OS 信任库
   ↓ → 自动信任，不报错

内网证书 (git.rd.local)
   ↓ 由 公司内部 CA 签发
   ↓ 内部 CA 根证书 不在 你系统里
   ↓ → "unable to get local issuer certificate"
```

### 三种处理方案

| 方案 | 安全性 | 操作 |
|------|-------|------|
| 拿到内部 CA 证书加进信任库 | ✅ 推荐 | 找管理员要 `.crt`，配置 `git config --global http."https://git.rd.local/".sslCAInfo /path/to/rd-ca.crt` |
| 单仓库关闭校验 | ⚠️ 凑合 | `git config http.sslVerify false`（在仓库目录下） |
| 全局关闭校验 | ❌ 危险 | `git config --global http.sslVerify false`，公网仓库也不校验，有中间人风险 |

临时拉一次：

```bash
GIT_SSL_NO_VERIFY=true git clone https://git.rd.local/ai/ai-pivot.git
```

---

## 七、最终建议

**短期拿代码**：HTTPS 临时关闭 sslVerify 走通。

**长期使用**：还是把 SSH 修好。原因：

- 不用每次输密码/token
- 不依赖管理员给 CA 证书
- 服务端日志能直接看出拒因，定位更快

**SSH 修不好怎么办**：让管理员看一眼 `journalctl -u sshd -f` 里你登录瞬间的日志，95% 的问题一行报错就定位了。

---

## 附：SSH 协议各阶段对应的常见问题

| 阶段 | 常见问题 | 表现 |
|------|---------|------|
| TCP 握手 | 端口被防火墙挡 / 端口不对 | `Connection refused` / `timeout` |
| 协议协商 | 客户端版本太老 | `no matching ... method found` |
| 密钥交换 | host key 变了 | `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` |
| 用户认证 | key 不匹配 | `Permission denied (publickey)` |
| 通道打开 | 仓库无权限 | `ERROR: Repository not found` |

排查时先看报错卡在哪个阶段，再针对性下钩子。

---

*本文记录于 2026 年 5 月，环境为 macOS + OpenSSH 9.x + 自建 Gitea 内网实例。*
