source ./tools.sh
#机器ip,可多台
ALL_NODES=(172.31.2.112 172.31.2.113 172.31.2.114)
#机器登录用户名,必须与IP一一对应
ALL_NODES_USERNAME=(root root root)

##初始化本地证书
privateInitLocalAuth
##各机器配置免密登录
initAllRemoteServersAuth "${ALL_NODES[*]}" "${ALL_NODES_USERNAME[*]}"
