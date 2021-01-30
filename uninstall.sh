#--------------------------------------使用说明----------------------------------------------
# 1.需要修改相关机器IP、账号等配置信息
# 2.需要主控机可以通过ssh访问相关机器
#--------------------------------------使用说明----------------------------------------------
#带颜色打印
function print() {
  echo -e "\033[32m$1\033[0m"
}
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
#校验任务状态
function checkStatus() {
  if [ $? -eq 1 ]; then
    echo $1 出错
    exit 1
  fi
}
#初始化本地证书
function privateInitLocalAuth() {
  print "=======================本机生成签名,如无需修改签名存放地址,回车即可======================="
  if [ ! -d ~/.ssh ]; then
    sudo mkdir -p ~/.ssh
  fi
  if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -t rsa
  fi
}
#初始化远程服务器免密登录
function initAllRemoteServersAuth() {
  print "=======================配置各机器免密登录======================="
  local index=0
  for item in ${ALL_NODES[@]}; do
    username=${ALL_NODES_USERNAME[${index}]}
    print "拷贝公钥到${item}机器,询问时输入yes,然后请输入${username}的密码"
    ssh-copy-id ${username}@${item}
    let index+=1
  done
}
#生成机器地址配置文件(供ansible使用)
function createEnvFile() {
  print "=======================生成环境配置文件======================="
  rm -rf ./configs/uninstall_env
  touch ./configs/uninstall_env
  index=1
  echo "[node]" >>./configs/uninstall_env
  for item in ${ALL_NODES[@]}; do
    echo "node-${index}  ansible_host=${item}" >>./configs/uninstall_env
    let index+=1
  done
}
function installAnsible() {
  print "=======================主控机安装ansible======================="
  a=$(uname -a)
  MAC="Darwin"
  UBUNTU="ubuntu"
  CENTOS="centos"
  if [[ $a =~ $MAC ]]; then
    brew install ansible
  elif [[ $a =~ $UBUNTU ]]; then
    apt-get install software-properties-common
    apt-add-repository ppa:ansible/ansible
    apt-get install ansible
  else
    yum -y install epel-release
    yum -y install ansible
  fi
}

##初始化本地证书
privateInitLocalAuth
#生成机器IP配置文件(ansible所需)
createEnvFile
##各机器配置免密登录
initAllRemoteServersAuth
#安装ansiable
installAnsible
#基于ansible安装k8s集群
ansible-playbook -i ./configs/uninstall_env -u root ./tasks/main_uninstall.yml --forks=1
