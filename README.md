## Install k8s 1.9 and docker 17.03ce for CentOS 7.x

#### 1 config the hosts file with ip address and hostname
#### 2 copy the all files to the remote master server
  ```
    ssh root@192.168.1.x mkdir -p /root/k8s
  ```
  ```
    scp -r * root@192.168.1.x:/root/k8s/
  ```
#### 3 run the shell script as root at remote master server  
   ```
     source init.sh && source install.sh 
   ```
