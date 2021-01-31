#--------------------------------------需配置内容----------------------------------------------
#k8s apiserver地址,master高可用必须用到,需要虚拟Ip做负载均衡.
#如果是测试环境,可填写第一台master机器的Ip,生产环境不推荐这样处理
K8S_API_SERVER_IP="172.31.2.112"

#k8s master机器ip,可多台
K8S_MASTERS=(172.31.2.112)
#k8s master机器登录用户名,必须与IP一一对应
K8S_MASTERS_USERNAME=(root)

#k8s node机器ip,可多台
K8S_NODES=(172.31.2.113)
#k8s node机器登录用户名,必须与IP一一对应
K8S_NODES_USERNAME=(root)

#可视化管理界面访问的域名地址
KUBOARD_HOST_NAME="kuboard.zhuhao.com"

#--------------------------------------需配置内容结束-------------------------------------------
#带颜色打印方法
function print() {
  echo -e "\033[32m$1\033[0m"
}

#--------------------------------------参数校验----------------------------------------------
if [ -z "${K8S_API_SERVER_IP}" ]; then
  print "K8S_API_SERVER_IP 为k8s服务器地址,必须配置"
  print "如需高可用: 请配置虚拟IP地址"
  print "无需高可用: 可配置master机器的IP(生产环境不推荐)"
  print "脚本已退出."
  exit 1
fi
masterIps=${#K8S_MASTERS[@]}
nodeIps=${#K8S_NODES[@]}
if [ ${masterIps} -lt 1 ]; then
  print "K8S_MASTERS:    master机器ip数组"
  print "K8S_MASTERS数组不能为空,至少要有一台master机器"
  print "参数校验出错,脚本已退出."
  exit 1
fi

masterUsernames=${#K8S_MASTERS_USERNAME[@]}
if [ ${masterIps} -ne ${masterUsernames} ]; then #是否相等
  print "K8S_MASTERS:           master机器ip数组"
  print "K8S_MASTERS_USERNAME:  master机器用户名数组"
  print "机器IP数组 与 用户名数组 必须长度一致且一一匹配"
  print "参数校验出错,脚本已退出."
  exit 1
fi

nodeUsernames=${#K8S_NODES_USERNAME[@]}
if [ ${nodeIps} -ne ${nodeUsernames} ]; then #是否相等
  print "K8S_NODES:           node机器ip数组"
  print "K8S_NODES_USERNAME:  node机器用户名数组"
  print "机器IP数组 与 用户名数组 必须长度一致且一一匹配"
  print "参数校验出错,脚本已退出."
  exit 1
fi
if [ -z "${KUBOARD_HOST_NAME}" ]; then
  KUBOARD_HOST_NAME="test.zhuhao.com"
fi
#--------------------------------------参数校验结束----------------------------------------------
#--------------------------------------使用说明----------------------------------------------

print "安装前准备:"
print "1.执行本脚前需修改集群相关机器IP、账号等配置信息,且至少有一台master机器"
print "2.本脚本仅支持目标集群机器为CentOs 7.7+系统"
print "3.本脚本支持的docker版本为: docker-ce-18.06.1.ce-3.el7 如已安装其他版本请先执行卸载脚本!!!(安装脚本同目录下 uninstall脚本)"
print "4.本脚本支持的K8s版本为: 1.18.2 如已安装其他版本请先执行卸载脚本!!!(安装脚本同目录下 uninstall脚本)"
print "5.执行本脚本需要本主控机可以通过ssh访问相关机器"
print ""
print ""
print "当前配置:"
print "k8s高可用虚拟IP地址:         ${K8S_API_SERVER_IP}"
print "k8s master机器:              ${K8S_MASTERS[*]}"
print "k8s master机器对应用户名:    ${K8S_MASTERS_USERNAME[*]}"

print "k8s node机器:                ${K8S_NODES[*]}"
print "k8s node机器对应用户名:      ${K8S_NODES_USERNAME[*]}"

print "是否确认已做好准备?  输入y=继续安装  输入其他任意值=退出"
read input
case $input in
y)
  pass
  ;;
n)
  exit 1
  ;;
*)
  exit 1
  ;;
esac
#--------------------------------------使用说明----------------------------------------------

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
  for item in ${K8S_MASTERS[@]}; do
    username=${K8S_MASTERS_USERNAME[${index}]}
    print "拷贝公钥到${item}机器,询问时输入yes,然后请输入${username}的密码"
    ssh-copy-id ${username}@${item}
    let index+=1
  done
  let index=0
  for item in ${K8S_NODES[@]}; do
    username=${K8S_NODES_USERNAME[${index}]}
    print "拷贝公钥到${item}机器,询问时输入yes,然后请输入${item}的密码"
    ssh-copy-id ${username}@${item}
    let index+=1
  done
}
#生成机器地址配置文件(供ansible使用)
function createEnvFile() {
  rm -rf ./configs/install_env
  touch ./configs/install_env
  index=1
  echo "[master]" >>./configs/install_env
  for item in ${K8S_MASTERS[@]}; do
    echo "k8s-master-${index}  ansible_host=${item}" >>./configs/install_env
    let index+=1
  done
  index=1
  echo "[node]" >>./configs/install_env
  for item in ${K8S_NODES[@]}; do
    echo "k8s-node-${index}  ansible_host=${item}" >>./configs/install_env
    let index+=1
  done
}
#生成组件所需配置文件
function createInitConfigFile() {
  rm -rf ./configs/install_config.yml
  touch ./configs/install_config.yml
  #写入nfs主机配置信息
  echo "#nfs的主机地址
nfs:
  server: ${K8S_MASTERS[0]}
#k8s可视化界面的host地址
kuboard:
  hosts: ${KUBOARD_HOST_NAME}
#K8s master高可用的广播地址及虚拟IP
#(如果是测试环境,可填写第一台master机器的Ip,生产环境不推荐这样处理)
k8s:
  apiserver:
      ip: ${K8S_API_SERVER_IP}
      host: apiserver.k8s" >>./configs/install_config.yml
}

function installAnsible() {
  print "=======================主控机安装ansible======================="
  a=$(uname -a)
  MAC="Darwin"
  UBUNTU="ubuntu"
  CENTOS="centos"
  if [[ $a =~ $MAC ]]; then
    print "安装ansiable,请输入本机密码"
    sudo brew install ansible
  elif [[ $a =~ $UBUNTU ]]; then
    apt-get install software-properties-common
    apt-add-repository ppa:ansible/ansible
    apt-get install ansible
  else
    yum -y install epel-release
    yum -y install ansible
  fi
}
function installK8s() {
  print "=======================开始安装k8s集群======================="
  #基于ansible安装k8s集群
  ansible-playbook -i ./configs/install_env -u root ./tasks/main_install.yml --forks=1
}
##初始化本地证书
privateInitLocalAuth
#生成机器IP配置文件(ansible所需)
createEnvFile
#生成组件所需配置文件
createInitConfigFile
##各机器配置免密登录
initAllRemoteServersAuth
#安装ansiable
installAnsible
#安装k8s集群
installK8s
