graphical
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

auth --useshadow --enablemd5
selinux --enforcing
rootpw --lock --iscrypted locked
#sshkey --username=root "ssh key"
user --groups=wheel --name=cannyos --password=password --gecos="cannyos"
firewall --disabled

bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate --onboot=on

services --enabled=sshd,rsyslog,cloud-init,cloud-init-local,cloud-config,cloud-final
# We use NetworkManager, and Avahi doesn't make much sense in the cloud
services --disabled=network,avahi-daemon

#zerombr
#ignoredisk --only-use=sda,sdb
#clearpart --all
#part /boot --size=300 --fstype="xfs"
#part pv.01 --grow
#volgroup atomicos pv.01
#logvol / --size=3000 --fstype="xfs" --name=root --vgname=atomicos
#logvol /var/lib/docker --size=3000 --fstype="xfs" --name=docker --vgname=atomicos

# Equivalent of %include fedora-repo.ks
ostreesetup --osname="centos-atomic-host" --remote="centos-atomic-host" --ref="centos-atomic-host/7/x86_64/standard" --url="http://%(server_ip)s:{{ REPO_PORT }}/repo/" --nogpg

reboot

%post --erroronfail









echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Bugfixes"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

# Anaconda is writing a /etc/resolv.conf from the generating environment.
# The system should start out with an empty file.
truncate -s 0 /etc/resolv.conf

# If you want to remove rsyslog and just use journald, remove this!
echo -n "Disabling persistent journal"
rmdir /var/log/journal/ 
echo . 

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf









echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: User Configuration"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

# older versions of livecd-tools do not follow "rootpw --lock" line above
# https://bugzilla.redhat.com/show_bug.cgi?id=964299
passwd -l root

userdel -r centos

mkdir -p /home/cannyos/
cd /home/cannyos/
mkdir --mode=700 .ssh
cat >> .ssh/authorized_keys << "PUBLIC_KEY"
{{ SSH_PUBLIC_KEY }}
PUBLIC_KEY
chmod 600 .ssh/authorized_keys
chown -R cannyos /home/cannyos









echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Network Configuration"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

echo -n "Network fixes"
# initscripts don't like this file to be missing.
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF



echo "-----------------------------------------------------------------------"
echo "CannyOS: Network Configuration"
echo "-----------------------------------------------------------------------"


# Remove network manager
systemctl stop network && \
systemctl stop NetworkManager && \
systemctl mask NetworkManager && \
systemctl start network && \
systemctl enable network && \
systemctl status network



# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules


ETH0_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)

N=1; IP_1=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')
N=2; IP_2=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')
N=3; IP_3=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')
N=4; IP_4=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')

echo "$IP_1.$IP_2.$IP_3.$IP_4"

ETH2_ADDRESS=$(echo "$IP_1.$(expr $IP_2 + 1).$IP_3.$IP_4")
ETH2_PREFIX=24
ETH2_GATEWAY=127.0.0.1
ETH2_DNS=127.0.0.1
ETH2_ADDRESS=$(echo "$IP_1.$(expr $IP_2 + 2).$IP_3.$IP_4")
ETH2_PREFIX=24
ETH2_GATEWAY=127.0.0.1
ETH2_DNS=127.0.0.1
ETH3_ADDRESS=$(echo "$IP_1.$(expr $IP_2 + 3).$IP_3.$IP_4")
ETH3_PREFIX=24
ETH3_GATEWAY=127.0.0.1
ETH3_DNS=127.0.0.1



cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
NAME="eth0"
TYPE="Ethernet"
ONBOOT="yes"
BOOTPROTO="dhcp"
PERSISTENT_DHCLIENT="yes"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE=eth1
NAME=eth1
TYPE=Ethernet
ONBOOT=yes
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_PRIVACY=no
EOF


# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

echo "$IP_1-$IP_2-$IP_3-$IP_4.cannyos.local" > /etc/hostname


# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount



# stop network manager from starting
systemctl mask NetworkManager


echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: NTPD"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
systemctl enable ntpd



echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Cockpit"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

# enable cockpit
systemctl start cockpit.service
systemctl enable cockpit.socket


echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: ETCD"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

# enable etcd
systemctl enable etcd.service



echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: SkyDNS"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


# Device that skydns is active on: this should NOT be public in production

SKYDNS_DEV=eth0
SKYDNS_IP=$(ip -f inet -o addr show $SKYDNS_DEV | cut -d\  -f 7 | cut -d/ -f 1)

cat > /var/usrlocal/bin/skydns-host-management << EOF
#!/bin/bash

while ! echo 'CannyOS: ETCD: now up' | etcdctl member list ; do sleep 1; done


# Configure the host to use skydns
cp -f /etc/resolv.conf /etc/resolv.conf.pre-skydns
sed -i '/Managed by CannyOS/d' /etc/resolv.conf
sed -i '/nameserver/d' /etc/resolv.conf
echo "# Managed by CannyOS: skydns" >> /etc/resolv.conf
echo "nameserver $SKYDNS_IP" >> /etc/resolv.conf
EOF
chmod +x /var/usrlocal/bin/skydns-host-management


cat > /etc/systemd/system/skydns.service << EOF
[Unit]
Description=CannyOS: Skydns Server
After=etcd.service
Requires=etcd.service

[Service]
TimeoutStartSec=0
ExecStartPre=/var/usrlocal/bin/skydns-host-management
ExecStart=/bin/skydns -addr=$SKYDNS_IP:53 -machines=http://127.0.0.1:4001 -nameservers=8.8.8.8:53

[Install]
WantedBy=multi-user.target
EOF

# enable skydns
systemctl enable skydns.service



echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Flanneld networking configuration"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"





cat > /etc/sysconfig/flanneld-conf.json << EOF
{
  "Network": "10.96.0.0/12",
  "SubnetLen": 24,
  "Backend": {
    "Type": "vxlan",
    "VNI": 2000
  }
}
EOF





cat > /etc/systemd/system/flanneld-conf.service << EOF
[Unit]
Description=CannyOS: Flanneld Configuration
After=etcd.service
Requires=etcd.service

[Service]
TimeoutStartSec=0
Type=oneshot
User=root
ExecStartPre=/bin/bash -c "while ! echo 'CannyOS: ETCD: now up' | etcdctl member list ; do sleep 1; done"
ExecStart=/bin/curl -L http://127.0.0.1:4001/v2/keys/atomic01/network/config -XPUT --data-urlencode value@/etc/sysconfig/flanneld-conf.json

[Install]
WantedBy=multi-user.target
EOF





cat > /etc/sysconfig/flanneld << EOF
# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD="http://127.0.0.1:4001"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_KEY="/atomic01/network"

# Any additional options that you want to pass
#FLANNEL_OPTIONS="-iface=\"eth0\""
EOF





cat > /etc/systemd/system/flanneld.path << EOF
[Path]
PathExists=/run/flannel/subnet.env
Unit=docker.service

[Install]
WantedBy=multi-user.target
EOF





cat > /etc/systemd/system/flanneld-conf.path << EOF
[Path]
PathExists=/run/flannel/configured
Unit=docker.service

[Install]
WantedBy=multi-user.target
EOF





mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/10-flanneld-network.conf << EOF
[Unit]
After=flanneld.service flanneld.path
Requires=flanneld.service flanneld.path 

[Service]
TimeoutStartSec=0
EnvironmentFile=/run/flannel/subnet.env
ExecStartPre=-/usr/sbin/ip link del docker0
ExecStart=
ExecStart=/usr/bin/docker -d --bip=\${FLANNEL_SUBNET} --mtu=\${FLANNEL_MTU} \$OPTIONS \$DOCKER_STORAGE_OPTIONS \$INSECURE_REGISTRY
EOF





cat > /etc/systemd/system/flanneld.service << EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target flanneld-conf.service flanneld-conf.path
Before=docker.service
Requires=flanneld-conf.service flanneld-conf.path

[Service]
TimeoutStartSec=0
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/usr/bin/flanneld -etcd-endpoints=\${FLANNEL_ETCD} -etcd-prefix=\${FLANNEL_ETCD_KEY} \$FLANNEL_OPTIONS
ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker

[Install]
RequiredBy=docker.service
EOF








echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Docker configuration"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"





cat > /etc/sysconfig/docker << EOF
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
#OPTIONS='--selinux-enabled --dns 8.8.8.8 -H tcp://$NODE_IP:2375 -H unix:///var/run/docker.sock'
OPTIONS='--dns $SKYDNS_IP -H tcp://$NODE_IP:2375 -H unix:///var/run/docker.sock'
DOCKER_CERT_PATH=/etc/docker

# Enable insecure registry communication by appending the registry URL
# to the INSECURE_REGISTRY variable below and uncommenting it
# INSECURE_REGISTRY='--insecure-registry '

# On SELinux System, if you remove the --selinux-enabled option, you
# also need to turn on the docker_transition_unconfined boolean.
# setsebool -P docker_transition_unconfined

# Location used for temporary files, such as those created by
# docker load and build operations. Default is /var/lib/docker/tmp
# Can be overriden by setting the following environment variable.
# DOCKER_TMPDIR=/var/tmp

# Controls the /etc/cron.daily/docker-logrotate cron job status.
# To disable, uncomment the line below.
# LOGROTATE=false
EOF




echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: FreeIPA: Initial Config"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"



# Set the hostname for the master ipa server
IPA_HOSTNAME=ipa.cannyos.local

# Set the initial admin password for the IPA server
IPA_PASSWORD=Password123


IPA_SERVER_NAME=ipa_server

DNS_NAMESERVER=8.8.8.8

cat > /etc/systemd/system/cannyos-ipa-server.service << EOF
[Unit]
Description=CannyOS: IPA Server Service
Documentation=http://git.cannycomputing.com/IPA/freeipa/wikis/home
Before=skydns.service
After=docker.service etcd.service
Requires=docker.service etcd.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill $IPA_SERVER_NAME
ExecStartPre=-/usr/bin/docker rm $IPA_SERVER_NAME
ExecStartPre=-/usr/bin/docker pull cannyos/ipa_server
ExecStartPre=-/usr/bin/docker start $IPA_SERVER_NAME
ExecStartPre=/var/usrlocal/bin/cannyos-ipa-server-config
ExecStart=/usr/bin/docker logs -f $IPA_SERVER_NAME
ExecStop=/usr/bin/docker stop $IPA_SERVER_NAME

[Install]
WantedBy=multi-user.target
EOF



cat > /var/usrlocal/bin/cannyos-ipa-server-config << EOF
#!/bin/bash
# Inform the service monitor that we are initialising
IPA_STATUS="init"
etcdctl mk /cannyos/config/ipa/status \$IPA_STATUS || etcdctl update /cannyos/config/ipa/status \$IPA_STATUS

# Launch the freeipa server
docker run -it -d \
    --name $IPA_SERVER_NAME \
    -h $IPA_HOSTNAME \
    -e PASSWORD=$IPA_PASSWORD \
    --dns $DNS_NAMESERVER \
    cannyos/ipa_server

IPA_HOSTNAME=\$(docker inspect --format='{{.Config.Hostname}}' $IPA_SERVER_NAME).\$(docker inspect --format='{{.Config.Domainname}}' $IPA_SERVER_NAME)

# Get the ip address of the ipa-server
IPA_IP=\$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $IPA_SERVER_NAME )

# Wait for DNS Resolution to start working
DNS_RESPONSE=\$(dig @\$IPA_IP \$IPA_HOSTNAME | awk '/ANSWER SECTION/ { getline; print }' | awk -F' ' '{print \$5}')
while [ "\$DNS_RESPONSE" != "\$IPA_IP" ]; do
  DNS_RESPONSE=\$(dig @\$IPA_IP \$IPA_HOSTNAME | awk '/ANSWER SECTION/ { getline; print }' | awk -F' ' '{print \$5}')
  sleep 1s
done

# Configure SkyDns to use IPA as its nameserver, and listen on all ports
etcdctl set /skydns/config "{\"dns_addr\":\"0.0.0.0:53\",\"ttl\":3600, \"nameservers\": [\"\$IPA_IP:53\"]}"

# Update the cluster registry with our info
etcdctl mk /cannyos/config/ipa/ip \$IPA_IP || etcdctl update /cannyos/config/ipa/ip \$IPA_IP
etcdctl mk /cannyos/config/ipa/hostname \$IPA_HOSTNAME || etcdctl update /cannyos/config/ipa/hostname \$IPA_HOSTNAME

# Inform the service monitor that we are ready
IPA_STATUS="ready"
etcdctl mk /cannyos/config/ipa/status \$IPA_STATUS || etcdctl update /cannyos/config/ipa/status \$IPA_STATUS

EOF
chmod +x /var/usrlocal/bin/cannyos-ipa-server-config














cat > /etc/systemd/system/cannyos-ipa-monitor.service << EOF
[Unit]
Description=CannyOS: IPA Service Monitor
After=etcd.service
Requires=etcd.service

[Service]
TimeoutStartSec=0
ExecStartPre=/var/usrlocal/bin/cannyos-ipa-monitor
ExecStart=/bin/bash -c "echo 'CannyOS IPA server: is now UP'"

[Install]
WantedBy=multi-user.target
EOF






cat > /var/usrlocal/bin/cannyos-ipa-monitor << EOF
#!/bin/sh

etcdctl get /cannyos/config/ipa/status || etcdctl mk /cannyos/config/ipa/status waiting

IPA_STATUS=\$(etcdctl get /cannyos/config/ipa/status)

while [ "\$IPA_STATUS" != "ready" ]; do
  etcdctl watch /cannyos/config/ipa/status
  IPA_STATUS=\$(etcdctl get /cannyos/config/ipa/status)
  sleep 1s
done

EOF
chmod +x /var/usrlocal/bin/cannyos-ipa-monitor



systemctl enable cannyos-ipa-monitor
systemctl enable cannyos-ipa-server



echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: OpenStack AIO"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

cat > /etc/systemd/system/canny-openstack-aio.service << EOF
[Unit]
Description=CannyOS: OpenStack AIO Service
After=docker.service cannyos-ipa-monitor.service
Requires=docker.service cannyos-ipa-monitor.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker pull cannyos/openstack-manager
ExecStartPre=/usr/bin/docker run --rm \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /root/canny:/root/canny \
    cannyos/openstack-manager pull
ExecStartPre=/usr/bin/docker run -d \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /root/canny:/root/canny \
    cannyos/openstack-manager start
ExecStart=/usr/bin/docker run --rm \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /root/canny:/root/canny \
    cannyos/openstack-manager status
ExecStop=/usr/bin/docker run --rm \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /root/canny:/root/canny \
    cannyos/openstack-manager stop

[Install]
WantedBy=multi-user.target
EOF


echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: SE Linux"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

setenforce 0

cat > /etc/sysconfig/selinux << EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#       enforcing - SELinux security policy is enforced.
#       permissive - SELinux prints warnings instead of enforcing.
#       disabled - SELinux is fully disabled.
SELINUX=permissive
# SELINUXTYPE= type of policy in use. Possible values are:
#       targeted - Only targeted network daemons are protected.
#       strict - Full SELinux protection.
SELINUXTYPE=targeted

# SETLOCALDEFS= Check local definition changes
SETLOCALDEFS=0
EOF




echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Cleanup"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"



# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot


echo "Removing random-seed so it's not the same in every image."
rm -f /var/lib/random-seed

echo "Packages within this cloud image:"
echo "-----------------------------------------------------------------------"
rpm -qa
echo "-----------------------------------------------------------------------"
# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

%end