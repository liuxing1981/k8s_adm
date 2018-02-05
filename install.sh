#!/bin/sh

DIST=dist

#install ali yum
#./aliyun_yum_repo.sh

#init all env
./init.sh

#all_hosts execute
cat hosts | awk '{print $1}' |  pdsh -w - /root/k8s_env.sh
 

#master
kubeadm init --kubernetes-version=v1.9.0 --pod-network-cidr=10.244.0.0/16
systemctl enable kubelet && sudo systemctl start kubelet
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source ~/.bash_profile
kubectl create -f $DIST/kube-flannel.yml

token=`kubeadm token create`
cat hosts | grep -v master | awk '{print $1}' |  pdsh -w - kubeadm join --token $token master:6443 --discovery-token-unsafe-skip-ca-verification

#clear 
cat hosts | grep -v master | awk '{print $1}' |  pdsh -w - "rm -rf /root/dist;rm -rf /root/k8s_env.sh"

