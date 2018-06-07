---
layout: page
title: About
description: 终生学习
keywords: Bob
comments: true
menu: 关于
permalink: /about/
---

我是Bob,

仰慕「优雅编码的艺术」。

终生学习，努力改变人生。

## 联系

{% for website in site.data.social %}
* {{ website.sitename }}：[@{{ website.name }}]({{ website.url }})
{% endfor %}

## Skill Keywords

{% for category in site.data.skills %}
### {{ category.name }}
<div class="btn-inline">
{% for keyword in category.keywords %}
<button class="btn btn-outline" type="button">{{ keyword }}</button>
{% endfor %}
</div>
{% endfor %}
