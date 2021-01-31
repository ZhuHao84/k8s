#--------------------------------------需配置内容----------------------------------------------
#k8s master机器ip
K8S_MASTERS="172.31.2.112"

#nfs相关配置
NFS_SERVER_HOST="172.31.2.112"
NFS_NODES=(172.31.2.113)

#mysql相关配置
#mysql的root账号登录密码
TMP_MYSQL_ROOT_PASSWORD="zhuhao123"

#redis相关配置
#nacos相关配置,
# mysql的host地址,如果mysql部署在k8s中,host可用  命名空间名.服务名
TMP_NACOS_MYSQL_HOST="172.31.2.189"
TMP_NACOS_MYSQL_PORT="3306"
TMP_NACOS_MYSQL_DB_NAME="nacos"
TMP_NACOS_MYSQL_USER="root"
TMP_NACOS_MYSQL_PASSWORD="zhuhao123"
#供外部访问的nacos管理页面域名
TMP_NACOS_HOST_NAME="nacos.zhuhao.com"

#rocketmq相关配置
TMP_ROCKET_ADMIN_HOST="rocketmq.zhuhao.com"

#dubboadmin相关配置
TMP_DUBBO_ADMIN_REGITSTRY_ADDRESS="zookeeper://zk:2181"
TMP_DUBBO_ADMIN_CONFIG_CENTER="zookeeper://zk:2181"
TMP_DUBBO_ADMIN_METADATA_REPORT_ADDRESS="zookeeper://zk:2181"
TMP_DUBBO_ADMIN_HOST="dubbo.zhuhao.com"

#xxl_job相关配置
TMP_XXL_JOB_MYSQL_HOST="172.31.2.189"
TMP_XXL_JOB_MYSQL_PORT="3306"
TMP_XXL_JOB_MYSQL_DB_NAME="xxl_job"
TMP_XXL_JOB_MYSQL_USER="root"
TMP_XXL_JOB_MYSQL_PASSWORD="123"
TMP_XXL_JOB_HOST_NAME="job.zhuhao.com"

#nginx相关配置
#nginx默认监听的域名,安装完毕后可通过k8s中的configMap,nginx-cm修改
TMP_NGINX_LISTEN_HOST="www.zhuhao.com"
#nfs服务器地址,用来存放web文件的机器
#如果是使用本脚本安装的集群,服务器地址即安装集群时配置的nfs地址
TMP_NGINX_NFS_SERVER_ADDRESS="192.168.1.51"
#web文件存放的目录
TMP_NGINX_NFS_SERVER_dir="/data/web"

#--------------------------------------需配置内容结束-------------------------------------------
#带颜色打印
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

function createEnvFile() {
  rm -rf ./configs/component_env
  touch ./configs/component_env
  echo "[master]" >./configs/component_env
  echo "k8s-master-1  ansible_host=${K8S_MASTERS}" >>./configs/component_env

  echo "[nfs-master]" >>./configs/component_env
  echo "nfs-master-1  ansible_host=${NFS_SERVER_HOST}" >>./configs/component_env

  echo "[nfs-node]" >>./configs/component_env
  index=1
  for item in ${NFS_NODES[@]}; do
    echo "nfs-node-${index}  ansible_host=${item}" >>./configs/component_env
    let index+=1
  done
}
#生成组件所需配置文件
function createConfigFile() {
  rm -rf ./configs/component_config.yml
  touch ./configs/component_config.yml
  #写入nfs主机配置信息
  echo "#mysql相关配置
mysql:
  root:
    password: ${TMP_MYSQL_ROOT_PASSWORD}
#nfs相关配置
nfs:
  server:
    host: ${NFS_SERVER_HOST}

#nacos相关配置
nacos:
  host:
    name: ${TMP_NACOS_HOST_NAME}
  mysql:
    db:
      host: ${TMP_NACOS_MYSQL_HOST}
      port: ${TMP_NACOS_MYSQL_PORT}
      name: ${TMP_NACOS_MYSQL_DB_NAME}
      user: ${TMP_NACOS_MYSQL_USER}
      password: ${TMP_NACOS_MYSQL_PASSWORD}
#xxljob相关配置
xxljob:
  host:
    name: ${TMP_XXL_JOB_HOST_NAME}
  mysql:
    db:
      host: ${TMP_XXL_JOB_MYSQL_HOST}
      port: ${TMP_XXL_JOB_MYSQL_PORT}
      name: ${TMP_XXL_JOB_MYSQL_DB_NAME}
      user: ${TMP_XXL_JOB_MYSQL_USER}
      password: ${TMP_XXL_JOB_MYSQL_PASSWORD}

#rocketmq相关配置
rocketmq:
  host:
    name: ${TMP_ROCKET_ADMIN_HOST}

#dubboadmin相关配置
dubboadmin:
  register:
      address: ${TMP_DUBBO_ADMIN_REGITSTRY_ADDRESS}
  config:
    center: ${TMP_DUBBO_ADMIN_CONFIG_CENTER}
  metadata_report:
    address: ${TMP_DUBBO_ADMIN_METADATA_REPORT_ADDRESS}
  host:
    name: ${TMP_DUBBO_ADMIN_HOST}

#nginx相关配置
nginx:
  listen:
    host: ${TMP_NGINX_LISTEN_HOST}
  nfs:
    server:
      address: ${TMP_NGINX_NFS_SERVER_ADDRESS}
      dir: ${TMP_NGINX_NFS_SERVER_DIR}
    " >./configs/component_config.yml

}

function createTaskFile() {
  MATHED=$1
  rm -rf ./tasks/component.yml
  touch ./tasks/component.yml
  echo "
- hosts: master
  vars_files: ../configs/component_config.yml
  roles:
    - ../roles/${MATHED} " >./tasks/component.yml
}
function createNfsTaskFile() {
  rm -rf ./tasks/component.yml
  touch ./tasks/component.yml
  echo "
- hosts: nfs-master
  vars_files: ../configs/component_config.yml
  roles:
    - ../roles/component_nfs_master
- hosts: nfs-node
  vars_files: ../configs/component_config.yml
  roles:
    - ../roles/component_nfs_node
    " >./tasks/component.yml
}
function runInstall() {
  createEnvFile
  createConfigFile
  createTaskFile $1
  ansible-playbook -i ./configs/component_env -u root ./tasks/component.yml --forks=1
}
function installMysql() {
  print "开始安装mysql"
  runInstall component_mysql
  checkStatus "安装mysql"
  echo "mysql安装成功  集群内访问方式: default.mysql:30306 集群外访问方式${K8S_MASTERS}:30306 root密码:${TMP_MYSQL_ROOT_PASSWORD}"
  echo "k8s中部署mysql可用于测试环境,不推荐在生产环境中使用"
}
function installRedis() {
  print "开始安装redis"
  runInstall component_redis
  checkStatus "安装redis"
  echo "redis安装成功  集群内访问方式: default.redis:30379 集群外访问方式${K8S_MASTERS}:30379"
}
function installNacos() {
  print "安装nacos前需配置好数据库信息,是否确认继续? y=继续,n=取消"
  print "安装nacos前需配置好数据库信息,是否确认继续? y=继续,n=取消"
  print "安装nacos前需配置好数据库信息,是否确认继续? y=继续,n=取消"
  read input
  case $input in
  y)
    print "开始安装nacos"
    runInstall component_nacos
    checkStatus "安装nacos"
    print "nacos安装成功  集群内访问方式: default.nacos:8848 集群外访问方式${TMP_NACOS_HOST_NAME} 默认账号:nacos 默认密码:nacos"
    ;;
  n)
    exit 0
    ;;
  esac
}
function installRocketMq() {
  print "开始安装rocketmq"
  runInstall component_rocketmq
  checkStatus "安装rocketmq"
  print "RocketMq安装成功  集群内访问方式: default.rocketmq-namesrv:9876 集群外访问方式${TMP_ROCKET_ADMIN_HOST}"
}

function installZk() {
  print "安装zk需确保k8s集群中至少有3台机上工作节点(worker node),是否确认继续? y=继续,n=取消"
  print "安装zk需确保k8s集群中至少有3台机上工作节点(worker node),是否确认继续? y=继续,n=取消"
  print "安装zk需确保k8s集群中至少有3台机上工作节点(worker node),是否确认继续? y=继续,n=取消"
  read input
  case $input in
  y)
    print "开始安装zk"
    runInstall component_zk
    checkStatus "安装zk"
    print "zk安装成功  集群内访问方式: default.zk:2181 集群外访问方式${K8S_MASTERS}:32181"
    ;;
  n)
    exit 0
    ;;
  esac
}
function installEs() {
  print "安装es需确保k8s集群中至少还富余有6G以上可用内存,是否确认继续? y=继续,n=取消"
  print "安装es需确保k8s集群中至少还富余有6G以上可用内存,是否确认继续? y=继续,n=取消"
  print "安装es需确保k8s集群中至少还富余有6G以上可用内存,是否确认继续? y=继续,n=取消"
  read input
  case $input in
  y)
    print "开始安装es"
    print installEs
    runInstall component_es
    checkStatus "安装es"
    print "es安装成功  集群内访问方式: default.es:9200 集群外访问方式${K8S_MASTERS}"
    ;;
  n)
    exit 0
    ;;
  esac

}
function installDubboAdmin() {
  print "安装DubboAdmin前需配置好注册中心等信息,是否确认继续? y=继续,n=取消"
  print "安装DubboAdmin前需配置好注册中心等信息,是否确认继续? y=继续,n=取消"
  print "安装DubboAdmin前需配置好注册中心等信息,是否确认继续? y=继续,n=取消"
  read input
  case $input in
  y)
    print "安装dubboAdmin"
    runInstall component_dubboadmin
    checkStatus "安装dubboAdmin"
    print "es安装成功 集群外访问方式${TMP_DUBBO_ADMIN_HOST}"
    ;;
  n)
    exit 0
    ;;
  esac
}
function installXxlJob() {
  print "安装xxl-job前需配置好数据库且已建好相关表,是否确认继续? y=继续,n=取消  (sql文件见 ./roles/component_xxl_job/files/xxl_job.sql)"
  print "安装xxl-job前需配置好数据库且已建好相关表,是否确认继续? y=继续,n=取消  (sql文件见 ./roles/component_xxl_job/files/xxl_job.sql)"
  print "安装xxl-job前需配置好数据库且已建好相关表,是否确认继续? y=继续,n=取消  (sql文件见 ./roles/component_xxl_job/files/xxl_job.sql)"
  read input
  case $input in
  y)
    print "安装xxl-job"
    runInstall component_xxl_job
    checkStatus "安装xxl-job"
    print "xxl-job安装成功 集群外访问方式${TMP_XXL_JOB_HOST_NAME}/xxl-job-admin 默认账号:admin 默认密码:123456"
    ;;
  n)
    exit 0
    ;;
  esac
}
function installNginx() {
  print "安装nginx至k8s,配置如下:"
  print "监听域名:            ${TMP_NGINX_LISTEN_HOST}"
  print "web文件存放机器Ip:    ${TMP_NGINX_NFS_SERVER_ADDRESS}"
  print "web文件存放目录:      ${TMP_NGINX_NFS_SERVER_DIR}"
  print "是否确认继续?         y=继续,n=取消"
  read input
  case $input in
  y)
    print "安装nginx"
    runInstall component_nginx
    checkStatus "安装nginx"
    print "nginx安装成功 集群外访问方式${TMP_NGINX_LISTEN_HOST}"
    ;;
  n)
    exit 0
    ;;
  esac
}
installNfs() {
  print "安装nfs至k8s,配置如下:"
  print "nfs master服务器地址:            ${NFS_SERVER_HOST}"
  print "nfs node节点:                   ${NFS_NODES[*]}"
  print "是否确认继续?         y=继续,n=取消"
  read input
  case $input in
  y)
    print "安装nfs"
    createEnvFile
    createConfigFile
    createNfsTaskFile
    ansible-playbook -i ./configs/component_env -u root ./tasks/component.yml --forks=1
    checkStatus "安装nfs"
    print "nfs安装成功"
    ;;
  n)
    exit 0
    ;;
  esac
}
function dispatchMethod() {
  if [ -z "$1" ]; then
    print "本脚本用于部署组件至K8S"
    print "使用前请确保已在本脚本中配置了各组件必备参数"
    print "命令菜单列表:"
    print " 输入 0 或 exit        退出脚本"
    print " 输入 1 或 nfs         安装nfs"
    print " 输入 2 或 mysql       安装mysql"
    print " 输入 3 或 redis       安装redis"
    print " 输入 4 或 nacos       安装nacos"
    print " 输入 5 或 rocketmq    安装rocketmq"
    print " 输入 6 或 zk          安装zk"
    print " 输入 7 或 es          安装es"
    print " 输入 8 或 dubboAdmin  安装dubboAdmin"
    print " 输入 9 或 xxljob      安装xxl-job"
    print " 输入其他任意值          打印菜单"
    print "请输入要执行的方法名称:"
    read input
    dispatchMethod $input
  else
    case $1 in
    1 | mysql)
      installNfs
      ;;
    2 | mysql)
      installMysql
      ;;
    3 | redis)
      installRedis
      ;;
    4 | nacos)
      installNacos
      ;;
    5 | rocketmq)
      installRocketMq
      ;;
    6 | zk)
      installZk
      ;;
    7 | es)
      installEs
      ;;
    8 | dubboAdmin)
      installDubboAdmin
      ;;
    9 | xxljob)
      installXxlJob
      ;;
    10 | nginx)
      installNginx
      ;;
    0 | exit)
      exit 0
      ;;
    *)
      dispatchMethod
      ;;
    esac
  fi
}
dispatchMethod $1
