#!/bin/sh

set -e

pxe_server_ip=$( ip -f inet -o addr show $INTERFACE | cut -d\  -f 7 | cut -d/ -f 1 )

echo Server IP: $pxe_server_ip

#/bin/bash

# Update pxelinux config to point real server ip
sed -i "s/%(server_ip)s/$pxe_server_ip/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/%(server_ip)s/$pxe_server_ip/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ SERVER_IP }}/$pxe_server_ip/g" /usr/share/nginx/html/cloudconfig/*
nginx
cat /var/lib/tftpboot/pxelinux.cfg/default


sed -i "s/{{ SSH_PUBLIC_KEY }}/$SSH_PUBLIC_KEY/g" /usr/share/nginx/html/ks/*


# Update discovery token, bootstrap with 3 nodes
ETCD_DISCOVERY_TOKEN=$(wget -qO- https:\/\/discovery.etcd.io\/new?size=3)
echo "ETCD discovery token: $ETCD_DISCOVERY_TOKEN"
sed -i "s,{{ ETCD_DISCOVERY_TOKEN }},$ETCD_DISCOVERY_TOKEN,g" /usr/share/nginx/html/cloudconfig/*


/bin/bash








pxe_server_ip=$( ip -f inet -o addr show $INTERFACE | cut -d\  -f 7 | cut -d/ -f 1 )

DHCP_START=10.30.0.100
DHCP_END=10.30.0.253
DHCP_NETMASK=255.255.255.0

dnsmasq \
    --dhcp-range=$INTERFACE,$DHCP_START,$DHCP_END,$DHCP_NETMASK \
    --dhcp-option=option:router,$pxe_server_ip \
    --dhcp-boot=pxelinux.0,pxeserver,$pxe_server_ip \
    --pxe-service=x86PC,"Install CannyOS",pxelinux \
    --enable-tftp \
    --tftp-root=/var/lib/tftpboot \
    --user=root \
    --no-daemon


#docker run --net=host --privileged -it -e INTERFACE=enp5s0 cannyos/installer
