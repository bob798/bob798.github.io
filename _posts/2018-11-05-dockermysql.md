---
layout: post
categories: blog
title: Docker 部署 Mysql
date: 2018-11-05 17:43:54 +0800
description: docker mysql
keywords: docker mysql
---


#Docker 部署 Mysql

> 这阶段微服务也是火的不要不要的，咱也要玩玩。


- 到docker的hub中拉取mysql镜像
- 5.5 是版本号，不加默认是最新版本

```shell
sudo docker pull mysql:5.5
```

- 运行mysql容器
- 参数说明：--name 后为镜像名称，-p 容器3306端口映射到本机3306端口（前为本机，后为容器）， -d 守护进程运行，PASSWORD 为密码

```shell
sudo docker run --name first-mysql -p 3306:3306 -e MYSQL\_ROOT\_PASSWORD=mysql -d mysql
```
- 查看容器状态

```shell
sudo docker ps -a
```
- 若要访问mysql数据库，需要安装mysql-client

```shell
sudo apt-get install mysql-cliect-core-5.5
```
- 访问服务器
- 密码为mysql，192.168.1.88为本机ip

```shell
mysql -h 192.168.1.88 -p 3306 -u root -p mysql
```
> docker安装mysql，确实很省事。
但，docker中不能存放数据，需要配置将数据文件存到容器外面
