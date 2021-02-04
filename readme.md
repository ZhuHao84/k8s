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

## 已支持的组件
组件名称     |  组件用途              | 能否用于生产 | 是否默认安装
---|---|---|---
kuboard     | 可视化控制面板                  |     可     |     是    
matrics     | 资源数据采集                    |     可     |     是
helm        | k8s组件安装工具                 |     可     |     是
ingress     | 发布应用(域名访问服务)           |     可     |    是
nfs         | 文件持久化                     |  高可用待优化 |    否
mysql       | 关系型数据库                    | 高可用但不推荐|   否
redis       | 键值对数据库                    |    不推荐    |   否
zk          | 微服务注册中心(依赖nfs)          |    高可用   |    否
DubboAdmin  | 微服务监控面板                   |     可    |     否
nacos       | 微服务注册中心/配置中心(依赖nfs)   |    高可用   |    否
xxl-job     | 分布式任务调度中心               |    高可用   |    否
es          | 全文检索搜索引擎                 |    待验证   |    否
nginx       | web应用发布                    |    高可用   |    否
rocketmq    | 消息队列                       |    待验证   |    否


