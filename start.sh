#!/bin/bash
set -e


echo Setting up iptables... && \
iptables -t nat -A POSTROUTING -j MASQUERADE


echo Waiting for pipework to give us the eth1 interface... && \
/bin/pipework --wait

INTERFACE=eth1

    
ROUTER_IP=$( ip -f inet -o addr show $INTERFACE | cut -d\  -f 7 | cut -d/ -f 1 )
echo Server IP: $ROUTER_IP


    
# Fix our cloudconfig folder for now
mkdir -p /usr/share/nginx/html/cloudconfig
touch /usr/share/nginx/html/cloudconfig/test

# Install the cannyos kernel and ramdisk
mkdir -p $TFTP_BOOT/cannyos
#curl http://$pxe_server_ip:$INSTALLER_PORT/installer/lorax/images/pxeboot/initrd.img > $TFTP_BOOT/cannyos/initrd.img
#curl http://$pxe_server_ip:$INSTALLER_PORT/installer/lorax/images/pxeboot/upgrade.img > $TFTP_BOOT/cannyos/upgrade.img
#curl http://$pxe_server_ip:$INSTALLER_PORT/installer/lorax/images/pxeboot/vmlinuz > $TFTP_BOOT/cannyos/vmlinuz

# Update pxelinux config to point real server ip
sed -i "s/%(server_ip)s/$pxe_server_ip/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/%(server_ip)s/$pxe_server_ip/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ SERVER_IP }}/$pxe_server_ip/g" /usr/share/nginx/html/cloudconfig/*


SSH_PUBLIC_KEY_SAFE=$(echo $SSH_PUBLIC_KEY | sed "s,/,\\\/,g")
sed -i "s/{{ SSH_PUBLIC_KEY }}/$SSH_PUBLIC_KEY_SAFE/g" /usr/share/nginx/html/ks/*


echo "ETCD discovery token: $ETCD_DISCOVERY_TOKEN"
sed -i "s,{{ ETCD_DISCOVERY_TOKEN }},$ETCD_DISCOVERY_TOKEN,g" /usr/share/nginx/html/ks/*
sed -i "s,{{ ETCD_DISCOVERY_TOKEN }},$ETCD_DISCOVERY_TOKEN,g" /usr/share/nginx/html/cloudconfig/*



echo "SWARM discovery token: $SWARM_TOKEN"
sed -i "s,{{ SWARM_TOKEN }},$SWARM_TOKEN,g" /usr/share/nginx/html/ks/*
sed -i "s,{{ SWARM_TOKEN }},$SWARM_TOKEN,g" /usr/share/nginx/html/cloudconfig/*



sed -i "s/{{ REPO_PORT }}/$REPO_PORT/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ REPO_PORT }}/$REPO_PORT/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ REPO_PORT }}/$REPO_PORT/g" /usr/share/nginx/html/cloudconfig/*

sed -i "s/{{ INSTALLER_PORT }}/$INSTALLER_PORT/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ INSTALLER_PORT }}/$INSTALLER_PORT/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ INSTALLER_PORT }}/$INSTALLER_PORT/g" /usr/share/nginx/html/cloudconfig/*

sed -i "s/{{ IMAGES_PORT }}/$IMAGES_PORT/g" /var/lib/tftpboot/pxelinux.cfg/default
sed -i "s/{{ IMAGES_PORT }}/$IMAGES_PORT/g" /usr/share/nginx/html/ks/*
sed -i "s/{{ IMAGES_PORT }}/$IMAGES_PORT/g" /usr/share/nginx/html/cloudconfig/*


nginx

cat /var/lib/tftpboot/pxelinux.cfg/default



# Launching dnsmasq
dnsmasq \
    --interface=eth1
    --dhcp-range=$DHCP_START,$DHCP_END,$DHCP_NETMASK,1h \
    --dhcp-option=option:router,$ROUTER_IP \
    --dhcp-boot=pxelinux.0,pxeserver,$ROUTER_IP \
    --pxe-service=x86PC,"CannyOS: Managed Boot",pxelinux \
    --enable-tftp \
    --tftp-root=/var/lib/tftpboot \
    --user=root \
    --no-daemon
