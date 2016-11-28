---
layout: post
categories: Blog
title: github-搭建博客
date: 2016-11-29 05:54:24 +0800
description: github-搭建博客
keywords: jekyll github blog
---

#GitHub 搭建个人博客

---

- 以下操作均基于Linux系统，且拥有GitHub账号（注册十分简单）

---

- 安装git，只需一条命令

```shell
sudo apt-get install git
```
- 安装完成后，需要设置一下。
- 告知你的门户

```shell
git cofig --global user.name"Your Name"
git config --global user.mail"mail@mail.com"
```
- 创建目录并进入

```shell
mkdir gittest
```
- 将目录变成git可管理的仓库

```shell
git init
```
- 返回下面说明，并多一个.git目录

```shell
Initialized empty Git repository in /Users/.git/
```
- 配置SSH keys

```shell
ssh-keygen -t rsa -C "yourmail@youremail.com"<此邮箱为GitHub注册邮箱>
```
 -  返回以下信息，回车即可

```shell
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/your_user_directory/.ssh/id_rsa):
```
  - 出现下面提示，继续回车

```shell
Enter passphrase (empty for no passphrase)
```
 - 复制秘钥
```shell
cd ~/.ssh
cat  id_rsa.pub<复制显示的秘钥>
```
 - 添加SSH Key到自己的GitHub
Settings>SSH and GPG keys

 - 关联github远程仓库
- “/”后为你的github厂库
- 最后可命名目录名
```shell
git remote add origin 
git@github.com:Directory/yourname.git
```
- 创建第一个html文件
```shell
printf "hello world.\n" > index.html
```
- 添加文件到仓库
```shell
git add index.html
```
- 提交文件到厂库（"-m" 后为提交说明）
```shell
git commit -m "first commit "
```
- 推送到GitHub
```shell
git push origin master
```
- 这样就可以访问你的GitHubPage，看到hello world
