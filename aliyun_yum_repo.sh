#!/bin/sh
cat /etc/yum.repos.d/CentOS-Base.repo | grep aliyun > /dev/null
if [ $? != 0 ];then
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
	curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	yum makecache
fi
