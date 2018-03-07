#!/bin/bash
shopt -s expand_aliases 
alias hosts="grep -Ev '^#|^$' hosts"
master=`hosts | awk '{print $1}' | head -1`
nodes=`hosts | awk '{print $1}' | grep -v $master`
echo $master
echo $nodes
for node in $nodes;do
    ssh root@$node -i ~/.ssh/ci.private_key "sed -i '/PasswordAuthentication no/d' /etc/ssh/sshd_config  && systemctl restart sshd"
done
ssh root@$master -i ~/.ssh/ci.private_key "mkdir -p /root/k8s && sed -i '/PasswordAuthentication no/d' /etc/ssh/sshd_config  &&  systemctl restart sshd"
sleep 5
scp -i ~/.ssh/ci.private_key -r * root@$master:/root/k8s 
ssh root@$master -i ~/.ssh/ci.private_key
