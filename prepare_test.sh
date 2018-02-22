ssh k8s6 "mkdir -p /root/k8s && sed -i '/PasswordAuthentication no/d' /etc/ssh/sshd_config  &&  systemctl restart sshd"
ssh k8s6-node "sed -i '/PasswordAuthentication no/d' /etc/ssh/sshd_config  && systemctl restart sshd"
scp -r * k8s6:/root/k8s
ssh k8s6
