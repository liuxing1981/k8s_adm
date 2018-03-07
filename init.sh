#!/bin/bash
HOST_USERNAME=root
HOST_PASSWD=centling
DIST=dist
PDSH=$DIST/pdsh
EXPECT=$DIST/expect
declare -A all_host=()
new_nodes=

#add aliyun yum repo
./aliyun_yum_repo.sh

#install ssh
ssh_install() {
    if ! ssh -V;then
        yum install -y openssh-server openssh-clients
        systemctl start sshd && systemctl enable sshd
    fi
}

ssh_keygen() {
  echo "生成管理节点公钥";
  expect -c "
    set timeout 1;
    spawn ssh-keygen -t rsa;
    expect \"save the key\" {send \"\n\";};
    expect \"empty for no passphrase\" {send \"\n\"};
    expect \"Overwrite (y/n)?\" {send \"y\n\"};
    expect \"same passphrase again:\" {send \"\n\"};
    expect eof;"
}

save_ssh_keys() {
  echo "管理节点免密登录 $1";
  expect -c "
    set timeout 1;
    spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub $HOST_USERNAME@$1;
    expect \"(yes/no)?\" {send \"yes\n\"};
    expect \"password:\" {send \"$HOST_PASSWD\n\"};
    exec sleep 1;
    expect root@* {send exit\n};
    expect eof;"
}

verify_ssh_keys() {
  echo "验证管理节点免密登录 $1"
  expect -c "
    set timeout 1;
    spawn ssh -o GSSAPIAuthentication=no $HOST_USERNAME@$1;
    expect \"(yes/no)?\" {send \"yes\n\"};
    #expect root@* {send \"echo \"免密登录$1成功\"\n\"};
    expect root@* {send exit\n};
    expect eof;"
}

change_hostname() {
   ssh $HOST_USERNAME@$1 "hostnamectl --static set-hostname $2"
   echo "hostname is changed to $2"
}

init() {
    #load hosts file
    grep -Ev "^$|^#" hosts > /tmp/hosts
    while read line;do
        ip=$(echo $line| awk '{print $1}')
        hostname=$(echo $line| awk '{print $2}')
        if [ $all_hosts ];then
            if [[ ! $all_hosts =~ $hostname ]];then
                new_nodes="$new_nodes,$hostname"
	        all_host[$ip]=$hostname
            fi
        else 
            all_host[$ip]=$hostname
        fi 
    done < /tmp/hosts
    #install pdsh
    yum localinstall -y $PDSH/pdsh*.rpm
    #install expect
    yum localinstall -y $EXPECT/*.rpm
}


init
#create master ssh key
if [ ! -e ~/.ssh/id_rsa ];then
    ssh_keygen
fi


for ip in ${!all_host[@]}
do
    hostname=${all_host[$ip]}
    echo ===ip=$ip======host=$hostname================
    save_ssh_keys $ip
    sleep 1
    echo "$ip $hostname">>/etc/hosts
    verify_ssh_keys $hostname
    all_hosts="$all_hosts,$hostname"
#    #copy pdsh to all hosts
    scp -r $PDSH $hostname:/tmp/
    change_hostname $ip $hostname
done

#define env
alias hosts="grep -Ev '^$|^#' hosts"
all_hosts=`echo $all_hosts  | sed  -e "s/,,/,/g" -e "s/^,//" -e "s/,$//"`
master=`hosts | awk '{print $2}' | head -1`
nodes=`echo $all_hosts | sed -e "s/$master//" -e "s/^,//" -e "s/,$//" -e "s/,,/,/g"`
new_nodes=`echo $new_nodes | sed "s/^,//"`
echo "==============all_hosts=======$all_hosts========================"
echo "==============master=======$master========================"
echo "==============nodes=======$nodes========================"
echo "==============new_nodes=======$new_nodes========================"




##clear old variables
sed -i '/all_hosts=/d' ~/.bash_profile
sed -i '/master=/d' ~/.bash_profile
sed -i '/nodes=/d' ~/.bash_profile
#add new variables to the env
echo "export all_hosts=$all_hosts" >> ~/.bash_profile
echo "export master=$master" >> ~/.bash_profile
echo "export nodes=$nodes" >> ~/.bash_profile
echo "export new_nodes=$new_nodes" >> ~/.bash_profile
source ~/.bash_profile

###install pdsh in all nodes
if [ "$new_nodes" ];then
    echo ==============install pdsh on new nodes===============================
    pdsh -w $new_nodes "yum localinstall -y /tmp/pdsh/pdsh*.rpm"
    
    ##scp some files
    pdsh -w $new_nodes "mkdir -p /root/.ssh"
    pdcp -w $new_nodes /etc/hosts /etc/hosts
    pdcp -w $new_nodes /root/.ssh/id_rsa* /root/.ssh
    pdcp -w $new_nodes /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
    pdsh -w $new_nodes yum clean all && yum makecache
else 
    echo ==============install pdsh on nodes===============================
    pdsh -w $nodes "yum localinstall -y /tmp/pdsh/pdsh*.rpm"
    
    ##scp some files
    pdsh -w $nodes "mkdir -p /root/.ssh"
    pdcp -w $nodes /etc/hosts /etc/hosts
    pdcp -w $nodes /root/.ssh/id_rsa* /root/.ssh
    pdcp -w $nodes /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
    pdsh -w $nodes yum clean all && yum makecache
fi    
echo "=============init completed!==========================================="
##pdsh -w $all_hosts  "sed -i '/ForwardAgent/ {s/no/yes/;s/#//}' /etc/ssh/ssh_config"

