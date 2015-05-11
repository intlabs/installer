
#!/bin/sh
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
cat /etc/sysctl.conf
sysctl -p
firewall-cmd --get-zone-of-interface=eth0
firewall-cmd --get-zone-of-interface=eth1

firewall-cmd --zone=internal --change-interface=eth1
firewall-cmd --permanent --zone=internal --change-interface=eth1
firewall-cmd --get-zone-of-interface=eth1

firewall-cmd --zone=public --add-masquerade
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --zone=public --list-all


firewall-cmd --zone=public --add-port=80/tcp --permanent
## Port http

firewall-cmd --zone=public --add-port=53/udp --permanent
firewall-cmd --zone=public --add-port=53/tcp --permanent
## Port for DNS

firewall-cmd --zone=public --add-port=67/udp --permanent
firewall-cmd --zone=public --add-port=68/udp --permanent
## Port for DHCP

firewall-cmd --zone=public --add-port=69/udp --permanent
## Port for TFTP

firewall-cmd --zone=public --add-port=4011/udp --permanent
## Port for ProxyDHCP

## Apply rules
firewall-cmd --reload

systemctl enable firewalld
systemctl restart firewalld

firewall-cmd --zone=public --list-all
firewall-cmd --zone=internal --list-all
