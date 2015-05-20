#!/bin/bash
docker-storage-setup
systemctl stop docker
rm -rf /var/lib/docker/*
systemctl start docker
docker info


echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
cat /etc/sysctl.conf
sysctl -p



ssh-keygen -t rsa -b 4096 -C "cannyos" -N "" -f ~/.ssh/id_rsa
echo $(cat /root/.ssh/id_rsa.pub)


EXTERNAL_INTERFACE=eth0
INTERNAL_INTERFACE=eth1
INTERNAL_INTERFACE_IP=10.30.0.1
INTERNAL_INTERFACE_PREFIX=24



# Set the external interface to dhcp
cat > /etc/sysconfig/network-scripts/ifcfg-$EXTERNAL_INTERFACE << EOF
DEVICE="$EXTERNAL_INTERFACE"
NAME="$EXTERNAL_INTERFACE"
TYPE="Ethernet"
ONBOOT="yes"
BOOTPROTO="dhcp"
PERSISTENT_DHCLIENT="yes"
EOF

# Set the internal interface to the management network
cat > /etc/sysconfig/network-scripts/ifcfg-$INTERNAL_INTERFACE << EOF
DEVICE="$INTERNAL_INTERFACE"
NAME="$INTERNAL_INTERFACE"
TYPE="Ethernet"
ONBOOT="yes"
BOOTPROTO="none"
IPADDR="$INTERNAL_INTERFACE_IP"
PREFIX="$INTERNAL_INTERFACE_PREFIX"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
IPV6_PRIVACY="no"
EOF







export REPO_PORT=8012
export INSTALLER_PORT=8013

docker run -d -p $REPO_PORT:80 cannyos/atomic_dist_rpmostree
docker run -d -p $INSTALLER_PORT:80 cannyos/atomic_dist_installer:stable



git stash && git pull && \
docker build -t "cannyos/installer" $(pwd) && \
SWARM_TOKEN=$( docker run --rm swarm create ) && \
ETCD_DISCOVERY_TOKEN=$(wget -qO- https:\/\/discovery.etcd.io\/new?size=$ETCD_INITIAL_NODES) && \
SSH_PUBLIC_KEY=$(echo $(cat /root/.ssh/id_rsa.pub)) && \
docker run -it --rm --privileged \
--net=host \
-e INTERFACE=eth1 \
-e SSH_PUBLIC_KEY=$SSH_PUBLIC_KEY \
-e REPO_PORT=$REPO_PORT \
-e INSTALLER_PORT=$INSTALLER_PORT \
-e SWARM_TOKEN=$SWARM_TOKEN \
-e ETCD_INITIAL_NODES=1 \
-e DHCP_START=10.30.0.1 \
-e DHCP_END=10.30.255.255 \
-e DHCP_NETMASK=255.255.0.0 \
-e ETCD_DISCOVERY_TOKEN=$ETCD_DISCOVERY_TOKEN \
cannyos/installer







# Enable Nat
iptables -t nat -A POSTROUTING -o $EXTERNAL_INTERFACE -j MASQUERADE
iptables -A FORWARD -i $EXTERNAL_INTERFACE -o $INTERNAL_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $INTERNAL_INTERFACE -o $EXTERNAL_INTERFACE -j ACCEPT



firewall-cmd --get-zone-of-interface=$EXTERNAL_INTERFACE
firewall-cmd --get-zone-of-interface=$INTERNAL_INTERFACE

firewall-cmd --zone=internal --change-interface=$INTERNAL_INTERFACE
firewall-cmd --permanent --zone=internal --change-interface=$INTERNAL_INTERFACE
firewall-cmd --get-zone-of-interface=$INTERNAL_INTERFACE

firewall-cmd --zone=public --add-masquerade
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --zone=public --list-all


firewall-cmd --zone=internal --add-service=ssh --permanent  	## Port 22
firewall-cmd --zone=public --add-service=ssh --permanent  	## Port 22
firewall-cmd --zone=internal --add-service=ftp --permanent  	## Port 21
firewall-cmd --zone=internal --add-service=dns --permanent  	## Port 53
firewall-cmd --zone=internal --add-service=dhcp --permanent  	## Port 67
firewall-cmd --zone=internal --add-port=69/udp --permanent  	## Port for TFTP
firewall-cmd --zone=internal --add-port=4011/udp --permanent  ## Port for ProxyDHCP
firewall-cmd --reload  ## Apply rules


