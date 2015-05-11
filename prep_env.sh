#!/bin/bash

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
cat /etc/sysctl.conf
sysctl -p

EXTERNAL_INTERFACE=enp1s0
INTERNAL_INTERFACE=enp4s2
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