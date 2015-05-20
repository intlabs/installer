#!/bin/bash
docker-storage-setup
systemctl stop docker
rm -rf /var/lib/docker/*
systemctl start docker
docker info


#echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
#cat /etc/sysctl.conf
#sysctl -p



ssh-keygen -t rsa -b 4096 -C "cannyos" -N "" -f ~/.ssh/id_rsa
echo $(cat /root/.ssh/id_rsa.pub)






curl https://raw.github.com/jpetazzo/pipework/master/pipework > ~/pipework
chmod +x ~/pipework


