#!/bin/sh
K8S_HOME=/root/k8s
DIST=dist

#copy files to all nodes
if [ "$new_nodes" ];then
    pdsh -w $new_nodes mkdir -p $K8S_HOME 
    pdcp -w $new_nodes -r $K8S_HOME/* $K8S_HOME
    
    #all_hosts execute
    pdsh -w $new_nodes $K8S_HOME/k8s_env.sh
    pdsh -w $new_nodes "systemctl enable kubelet && systemctl start kubelet"
    token=`kubeadm token create`
    pdsh -w $new_nodes kubeadm join --token $token $master:6443 --discovery-token-unsafe-skip-ca-verification
    #clean new_nodes variable for next adding nodes
    sed -i '/new_nodes/d' ~/.bash_profile
    source ~/.bash_profile
    unset new_nodes
else
    echo "there is no new nodes in the hosts file! exit!"
fi
