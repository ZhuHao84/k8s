source ./tools.sh
#--------------------------------------使用说明----------------------------------------------
print "卸载前准备:"
print "1.执行本脚前需修改集群相关机器IP、账号等配置信息"
print "2.本脚本仅支持目标机器为CentOs系统"
print "3.执行本脚本需要本主控机可以通过ssh访问相关机器"
print "是否确认已做好准备?  输入y=继续卸载  输入其他任意值=退出"
read input
case $input in
y)
  pass
  ;;
*)
  exit 1
  ;;
esac
#--------------------------------------需配置内容----------------------------------------------
#所有机器ip,可多台
ALL_NODES=(172.31.2.112 172.31.2.113)
ALL_NODES_USERNAME=(root root)
#--------------------------------------需配置内容结束-------------------------------------------
#生成机器地址配置文件(供ansible使用)
function createEnvFile() {
  print "=======================生成环境配置文件======================="
  rm -rf ./configs/uninstall_env
  mkdir -p ./configs
  touch ./configs/uninstall_env
  index=1
  echo "[node]" >>./configs/uninstall_env
  for item in ${ALL_NODES[@]}; do
    echo "node-${index}  ansible_host=${item}" >>./configs/uninstall_env
    let index+=1
  done
}


##初始化本地证书
privateInitLocalAuth
#生成机器IP配置文件(ansible所需)
createEnvFile
##各机器配置免密登录
initAllRemoteServersAuth "${ALL_NODES[*]}" "${ALL_NODES_USERNAME[*]}"
#安装ansiable
installAnsible
#基于ansible安装k8s集群
ansible-playbook -i ./configs/uninstall_env -u root ./tasks/main_uninstall.yml --forks=1
