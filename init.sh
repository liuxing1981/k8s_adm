#!/bin/bash
HOST_USERNAME=root
HOST_PASSWD=centling
declare -A all_host=()


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
    while read line;do
        ip=$(echo $line| awk '{print $1}')
        hostname=$(echo $line| awk '{print $2}')
	all_host[$ip]=$hostname 	
    done < hosts
    #install pdsh
    cd dist/pdsh
    yum localinstall -y pdsh*.rpm
    #install expect
    cd ../expect 
    yum localinstall -y *.rpm    
    cd ../..    
}

init
for ip in ${!all_host[@]}
do
    hostname=${all_host[$ip]};
    ssh_keygen
    save_ssh_keys $ip
    sleep 1;
    echo "$ip $hostname">>/etc/hosts
    verify_ssh_keys $ip
done;

for ip in ${!all_host[@]}
do
    hostname=${all_host[$ip]};
    scp /etc/hosts root@$ip:/etc/hosts
    echo "change to aliyun yum repo"
    scp /etc/yum.repos.d/CentOS-Base.repo root@$ip:/etc/yum.repos.d/CentOS-Base.repo
    change_hostname $ip $hostname
    scp -r dist root@$ip:/root
    scp k8s_env.sh root@$ip:/root
done;
