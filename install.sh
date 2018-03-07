#!/bin/sh
K8S_HOME=/root/k8s
DIST=dist

#copy files to all nodes
pdsh -w $nodes mkdir -p $K8S_HOME 
pdcp -w $nodes -r $K8S_HOME/* $K8S_HOME

#all_hosts execute
pdsh -w $all_hosts $K8S_HOME/k8s_env.sh
 
#master execute
kubeadm init --kubernetes-version=v1.9.0 --pod-network-cidr=10.244.0.0/16
systemctl enable kubelet && systemctl start kubelet
sleep 10
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
#bash completion
echo "source <(kubectl completion bash)">> ~/.bash_profile
source ~/.bash_profile

kubectl create -f $DIST/kube-flannel.yml
sleep 10
token=`kubeadm token create`
pdsh -w $nodes kubeadm join --token $token $master:6443 --discovery-token-unsafe-skip-ca-verification

#clear 
#pdsh -w $nodes  "rm -rf K8S_HOME"
sleep 10


kubectl get nodes
