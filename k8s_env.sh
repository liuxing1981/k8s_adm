#/bin/bash

K8S_HOME=/root/k8s
DIST=$K8S_HOME/dist
#install docker
docker version || yum install -y $DIST/docker-ce-se*.rpm $DIST/docker-ce-17*.rpm
mkdir -p /etc/docker
cat << EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl start docker && systemctl enable docker

#stop firewall and selinux
systemctl stop firewalld && systemctl disable firewalld
if ! cat /etc/selinux/config | grep '^SELINUX=disabled';then
    cat SELINUX=disabled >> /etc/selinux/config
fi
setenforce 0
swapoff -a

echo "
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
" >> /etc/sysctl.conf
sysctl -p

#load docker images
docker load < $DIST/docker_images/etcd-amd64_v3.1.10.tar
docker load < $DIST/docker_images/flannel\:v0.9.1-amd64.tar
docker load < $DIST/docker_images/k8s-dns-dnsmasq-nanny-amd64_v1.14.7.tar
docker load < $DIST/docker_images/k8s-dns-kube-dns-amd64_1.14.7.tar
docker load < $DIST/docker_images/k8s-dns-sidecar-amd64_1.14.7.tar
docker load < $DIST/docker_images/kube-apiserver-amd64_v1.9.0.tar
docker load < $DIST/docker_images/kube-controller-manager-amd64_v1.9.0.tar
docker load < $DIST/docker_images/kube-scheduler-amd64_v1.9.0.tar
docker load < $DIST/docker_images/kube-proxy-amd64_v1.9.0.tar
docker load < $DIST/docker_images/pause-amd64_3.0.tar

#install k8s
cd $DIST
rpm -ivh socat-1.7.3.2-2.el7.x86_64.rpm
rpm -ivh kubernetes-cni-0.6.0-0.x86_64.rpm  kubelet-1.9.9-9.x86_64.rpm  kubectl-1.9.0-0.x86_64.rpm
rpm -ivh kubectl-1.9.0-0.x86_64.rpm
rpm -ivh kubeadm-1.9.0-0.x86_64.rpm

