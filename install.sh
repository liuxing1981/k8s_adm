#!/bin/sh

DIST=dist

#init all env
#./init.sh

#all_hosts execute
cat /tmp/hosts | awk '{print $1}' |  pdsh -w - /root/k8s_env.sh
 
MASTER=`cat /tmp/hosts | awk '{print $1}' | head -1`
#master
kubeadm init --kubernetes-version=v1.9.0 --pod-network-cidr=10.244.0.0/16
systemctl enable kubelet && sudo systemctl start kubelet
sleep 10
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source ~/.bash_profile
kubectl create -f $DIST/kube-flannel.yml
sleep 10
token=`kubeadm token create`
cat /tmp/hosts | grep -v $MASTER | awk '{print $1}' |  pdsh -w - kubeadm join --token $token $MASTER:6443 --discovery-token-unsafe-skip-ca-verification

#clear 
cat /tmp/hosts | grep -v $MASTER | awk '{print $1}' |  pdsh -w - "rm -rf /root/dist;rm -rf /root/k8s_env.sh"
sleep 10
kubectl get nodes
