#!/bin/sh

set -e

pxe_server_ip=$( ip -f inet -o addr show $INTERFACE | cut -d\  -f 7 | cut -d/ -f 1 )

echo Server IP: $pxe_server_ip

#/bin/bash
mkdir -p $TFTP_BOOT/cannyos
curl http://$pxe_server_ip:$INSTALLER_PORT/installer/lorax/images/pxeboot/initrd.img > $TFTP_BOOT/cannyos/initrd.img
curl http://$pxe_server_ip:$INSTALLER_PORT/installer/lorax/images/pxeboot/upgrade.img > $TFTP_BOOT/cannyos/upgrade.img
curl http://$pxe_server_ip:$INSTALLER_PORT/installer/lorax/images/pxeboot/vmlinuz > $TFTP_BOOT/cannyos/vmlinuz

# Update pxelinux config to point real server ip
sed -i "s/%(server_ip)s/$pxe_server_ip/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/%(server_ip)s/$pxe_server_ip/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ SERVER_IP }}/$pxe_server_ip/g" /usr/share/nginx/html/cloudconfig/*
nginx
cat /var/lib/tftpboot/pxelinux.cfg/default



SSH_PUBLIC_KEY_SAFE=$(echo $SSH_PUBLIC_KEY | sed "s,/,\\\/,g")

sed -i "s/{{ SSH_PUBLIC_KEY }}/$SSH_PUBLIC_KEY_SAFE/g" /usr/share/nginx/html/ks/*


sed -i "s/{{ REPO_PORT }}/$REPO_PORT/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ REPO_PORT }}/$REPO_PORT/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ REPO_PORT }}/$REPO_PORT/g" /usr/share/nginx/html/cloudconfig/*

sed -i "s/{{ INSTALLER_PORT }}/$INSTALLER_PORT/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ INSTALLER_PORT }}/$INSTALLER_PORT/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ INSTALLER_PORT }}/$INSTALLER_PORT/g" /usr/share/nginx/html/cloudconfig/*

sed -i "s/{{ IMAGES_PORT }}/$IMAGES_PORT/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ IMAGES_PORT }}/$IMAGES_PORT/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ IMAGES_PORT }}/$IMAGES_PORT/g" /usr/share/nginx/html/cloudconfig/*


# Update discovery token, bootstrap with 3 nodes
ETCD_DISCOVERY_TOKEN=$(wget -qO- https:\/\/discovery.etcd.io\/new?size=3)
echo "ETCD discovery token: $ETCD_DISCOVERY_TOKEN"
sed -i "s,{{ ETCD_DISCOVERY_TOKEN }},$ETCD_DISCOVERY_TOKEN,g" /usr/share/nginx/html/ks/*
sed -i "s,{{ ETCD_DISCOVERY_TOKEN }},$ETCD_DISCOVERY_TOKEN,g" /usr/share/nginx/html/cloudconfig/*



pxe_server_ip=$( ip -f inet -o addr show $INTERFACE | cut -d\  -f 7 | cut -d/ -f 1 )

DHCP_START=10.30.0.100
DHCP_END=10.30.0.253
DHCP_NETMASK=255.255.255.0

dnsmasq \
    --dhcp-range=$INTERFACE,$DHCP_START,$DHCP_END,$DHCP_NETMASK \
    --dhcp-option=option:router,$pxe_server_ip \
    --dhcp-boot=pxelinux.0,pxeserver,$pxe_server_ip \
    --pxe-service=x86PC,"CannyOS: Managed Boot",pxelinux \
    --enable-tftp \
    --tftp-root=/var/lib/tftpboot \
    --user=root \
    --no-daemon


#docker run --net=host --privileged -it -e INTERFACE=enp5s0 cannyos/installer
