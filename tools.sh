#带颜色打印方法
function print() {
  echo -e "\033[32m$1\033[0m"
}
#校验任务状态
function checkStatus() {
  if [ $? -eq 1 ]; then
    echo $1 出错
    exit 1
  fi
}

function installAnsible() {
  print "=======================主控机安装ansible======================="
  a=$(uname -a)
  MAC="Darwin"
  UBUNTU="ubuntu"
  CENTOS="centos"
  print "安装ansible中,如安装失败,请自行安装ansible后执行脚本"
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
  print "=======================配置机器免密登录======================="
  NODES=($1)
  USERNAMES=($2)
  NODES_LENGTH=${#K8S_MASTERS_USERNAME[@]}
  NODES_USERNAME_LENGTH=${#K8S_MASTERS_USERNAME[@]}
  if [ ${NODES_LENGTH} -ne ${NODES_USERNAME_LENGTH} ]; then #是否相等
    print "机器IP数组 与 用户名数组 必须长度一致且一一匹配"
    print "参数校验出错,脚本已退出."
    exit 1
  fi
  local index=0
  for item in ${NODES[@]}; do
    username=${USERNAMES[${index}]}
    print "拷贝公钥到${item}机器,询问时输入yes,然后请输入${username}的密码"
    ssh-copy-id ${username}@${item}
    let index+=1
  done
}
