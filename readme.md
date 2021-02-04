# 下一版本迭代计划(更新时间不确定)
> 安装组件时,支持自定义命名空间
> 添加skywalking部署支持
> 添加elk部署支持

# k8s一键部署脚本使用说明
***
## 目录结构
目录/文件名称            |  用途
---|--- 
docs                   | 一些说明文档
configs:               | 自动生成的临时配置文件保存目录
roles:                 | 任务定义文件目录
tasks:                 | 执行任务配置文件保存目录
install.sh:            | 安装k8s集群脚本
uninstall.sh:          | 卸载k8s的脚本
component_install.sh:  | 安装其他组件的脚本(mysql、redis等)
tools.sh               | 一些公用方法的封装

***
## 使用方法
* 安装K8s集群
>1.准备集群相关机器,至少一台master,CentOs7.7+系统

>2.下载并解压本脚本到linux或mac机器

>3.修改install.sh脚本中的配置

>4.执行nstall.sh脚本

>5.如果集群相关机器已安装过docker或k8s,为防止版本冲突,安装前建议卸载

* 卸载k8s集群
>1.下载并解压本脚本到linux或mac机器

>2.修改uninstall.sh脚本中的配置

>3.执行uninstall.sh脚本

* 安装组件
>1.下载并解压本脚本到linux或mac机器

>2.修改component_install.sh脚本中的配置

>3.执行component_install.sh