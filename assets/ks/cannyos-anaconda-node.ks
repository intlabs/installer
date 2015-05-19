text
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

selinux --enforcing

auth --useshadow --enablemd5

rootpw --lock --iscrypted locked

user --groups=wheel --name=cannyos --password=password --gecos="cannyos"


firewall --disabled
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate --onboot=on


services --enabled=sshd,rsyslog,cloud-init,cloud-init-local,cloud-config,cloud-final
# We use NetworkManager, and Avahi doesn't make much sense in the cloud
services --disabled=network,avahi-daemon


bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"


zerombr
clearpart --all --initlabel --drives=sda,sdb
part /boot --size=300 --fstype="ext4"
part pv.01 --size=1000 --grow --ondisk=sda
part pv.02 --size=1000 --grow --ondisk=sdb
volgroup cannyos pv.01 pv.02
logvol / --size=8192 --fstype="xfs" --name=root --vgname=cannyos


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


# Fixing the locale settings
cat > /etc/environment << EOF
LANG="en_US.utf-8"
LC_ALL="en_US.utf-8"
EOF





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



# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules



echo "-----------------------------------------------------------------------"
echo "CannyOS: INTERFACES"
echo "-----------------------------------------------------------------------"

# ALL NODES
#  * eth0 will be used for pxe, etcd, flanneld                  10.30.0.0 255.255.0.0 (assigned via PXE DCHP server on master node)
#  * eth1 will be used for neutron - aka the public interfaces  10.0.2.0  255.255.0.0 (managed via neutron)
#  * eth2 will be used for ceph and/or swift                    10.32.0.0 255.255.0.0 (shares subnet ranges with eth0 initial ip addr)
# MASTER NODE
#  * eth3 will be connected to the public internet on the master node (assigned by DHCP)

ETH0_IP=$(ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1)

N=1; IP_1=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')
N=2; IP_2=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')
N=3; IP_3=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')
N=4; IP_4=$(echo $ETH0_IP | awk -F'.' -v N=$N '{print $N}')
#echo "$IP_1.$IP_2.$IP_3.$IP_4"

ETH2_IP=$(echo "$IP_1.$(expr $IP_2 + 2).$IP_3.$IP_4")
ETH2_PREFIX=24

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
NAME="eth0"
TYPE="Ethernet"
ONBOOT="yes"
BOOTPROTO="dhcp"
PERSISTENT_DHCLIENT="yes"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE="eth1"
NAME="eth1"
TYPE="Ethernet"
ONBOOT="yes"
BOOTPROTO="none"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
IPV6_PRIVACY="no"
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 << EOF
DEVICE="eth2"
NAME="eth2"
TYPE="Ethernet"
ONBOOT="yes"
BOOTPROTO="none"
IPADDR="$ETH2_IP"
PREFIX="$ETH2_PREFIX"
IPV6INIT="no"
IPV6_AUTOCONF="no"
IPV6_DEFROUTE="no"
IPV6_FAILURE_FATAL="no"
IPV6_PRIVACY="no"
EOF

#cat > /etc/sysconfig/network-scripts/ifcfg-eth3 << EOF
#DEVICE="eth3"
#NAME="eth3"
#TYPE="Ethernet"
#ONBOOT="yes"
#BOOTPROTO="dhcp"
#PERSISTENT_DHCLIENT="yes"
#EOF


echo "--------------------------------------------------------------"
echo "CannyOS: Hosts"
echo "--------------------------------------------------------------"


cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF


echo "--------------------------------------------------------------"
echo "CannyOS: Hostname"
echo "--------------------------------------------------------------"


echo "$IP_1-$IP_2-$IP_3-$IP_4.cannyos.local" > /etc/hostname





echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: ETCD"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


ETCD_DEV=eth0
ETCD_IP=$( ip -f inet -o addr show $ETCD_DEV | cut -d\  -f 7 | cut -d/ -f 1 )

cat > /etc/etcd/etcd.conf << EOF
# [member]
ETCD_NAME=$NODE_IP
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#ETCD_SNAPSHOT_COUNTER="10000"
#ETCD_HEARTBEAT_INTERVAL="100"
#ETCD_ELECTION_TIMEOUT="1000"
ETCD_LISTEN_PEER_URLS="http://127.0.0.1:2380,http://$ETCD_IP:7001"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:2379,http://$ETCD_IP:4001"
#ETCD_MAX_SNAPSHOTS="5"
#ETCD_MAX_WALS="5"
#ETCD_CORS=""
#
#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$ETCD_IP:7001"
# if you use different ETCD_NAME (e.g. test), set ETCD_INITIAL_CLUSTER value for this name, i.e. "test=http://..."
#ETCD_INITIAL_CLUSTER="default=http://localhost:2380,default=http://localhost:7001"
#ETCD_INITIAL_CLUSTER_STATE="new"
#ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://$ETCD_IP:4001"
ETCD_DISCOVERY="{{ ETCD_DISCOVERY_TOKEN }}"
#ETCD_DISCOVERY_SRV=""
#ETCD_DISCOVERY_FALLBACK="proxy"
#ETCD_DISCOVERY_PROXY=""
#
#[proxy]
#ETCD_PROXY="off"
#
#[security]
#ETCD_CA_FILE=""
#ETCD_CERT_FILE=""
#ETCD_KEY_FILE=""
#ETCD_PEER_CA_FILE=""
#ETCD_PEER_CERT_FILE=""
#ETCD_PEER_KEY_FILE=""
EOF


cat > /etc/systemd/system/etcd.service << EOF
[Unit]
Description=Etcd Server
After=network.target

[Service]
Type=simple
# etcd logs to the journal directly, suppress double logging
StandardOutput=null
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
User=etcd
TimeoutStartSec=0
ExecStart=/usr/bin/etcd \
  -name \${ETCD_NAME} \
  -initial-advertise-peer-urls \${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
  -listen-peer-urls \${ETCD_LISTEN_PEER_URLS} \
  -listen-client-urls \${ETCD_LISTEN_CLIENT_URLS} \
  -discovery \${ETCD_DISCOVERY}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF




echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: SkyDNS"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


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



echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Flanneld networking configuration"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


echo "--------------------------------------------------------------"
echo "CannyOS: Flanneld: Initial settings"
echo "--------------------------------------------------------------"


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


echo "--------------------------------------------------------------"
echo "CannyOS: Flanneld: Configuration: Service"
echo "--------------------------------------------------------------"


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
ExecStart=/bin/curl -L http://$ETCD_IP:4001/v2/keys/cannyos/network/config -XPUT --data-urlencode value@/etc/sysconfig/flanneld-conf.json

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


echo "--------------------------------------------------------------"
echo "CannyOS: Flanneld: Service"
echo "--------------------------------------------------------------"


cat > /etc/sysconfig/flanneld << EOF
# Flanneld configuration options  

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD="http://$ETCD_IP:4001"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_KEY="/cannyos/network"

# Any additional options that you want to pass
#FLANNEL_OPTIONS="-iface=\"eth0\""
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


# This detects that flanneld is reday to go
cat > /etc/systemd/system/flanneld.path << EOF
[Path]
PathExists=/run/flannel/subnet.env
Unit=docker.service

[Install]
WantedBy=multi-user.target
EOF


echo "--------------------------------------------------------------"
echo "CannyOS: Flanneld: Docker Service: Drop In"
echo "--------------------------------------------------------------"


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


echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Docker"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


echo "--------------------------------------------------------------"
echo "CannyOS: Docker: Storage Setup"
echo "--------------------------------------------------------------"


cat > /etc/systemd/system/canny-docker-storage.service << EOF
[Unit]
Description=CannyOS: Docker Storage Setup
Before=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/var/usrlocal/bin/canny-docker-storage

[Install]
WantedBy=multi-user.target
EOF


cat > /var/usrlocal/bin/canny-docker-storage << EOF
#!/bin/bash
DOCKER_POOL=\$(lvs | grep docker-pool)
if [ -z "\$DOCKER_POOL" ]; then 
    echo "CannyOS: No docker storage pool detected: Creating"
    docker-storage-setup
    rm -rf /var/lib/docker/*
fi
EOF
chmod +x /var/usrlocal/bin/canny-docker-storage






echo "--------------------------------------------------------------"
echo "CannyOS: Docker: Config"
echo "--------------------------------------------------------------"

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
echo "CannyOS: DNS Container Discovery Service"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


echo "--------------------------------------------------------------"
echo "CannyOS: DNS Container Discovery Service: Config"
echo "--------------------------------------------------------------"

DNS_DISCOVER_HOST_DEV=eth0
DNS_DISCOVER_HOST_IP=$(ip -f inet -o addr show $DNS_DISCOVER_HOST_DEV | cut -d\  -f 7 | cut -d/ -f 1)


echo "--------------------------------------------------------------"
echo "CannyOS: DNS Container Discovery Service: Service"
echo "--------------------------------------------------------------"
cat > /etc/systemd/system/cannyos-dns-discovery.service << EOF
[Unit]
Description=CannyOS: DNS Container Discovery Service
Documentation=http://git.cannycomputing.com/Atomic/DNS/tree/master/discover
After=etcd.service docker.service
Requires=etcd.service docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker kill cannyos-dns-discovery 
ExecStartPre=-/usr/bin/docker rm cannyos-dns-discovery 
ExecStartPre=-/usr/bin/docker pull cannyos/dns_discover
ExecStartPre=/usr/bin/docker run -d \
                            --net=host \
                            --name cannyos-dns-discovery \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -e HOST_IP=$DNS_DISCOVER_HOST_IP \
                            -e ETCD_HOST=$ETCD_IP:4001 \
                            cannyos/dns_discover
ExecStart=/usr/bin/docker logs -f cannyos-dns-discovery 
ExecStop=/usr/bin/docker stop cannyos-dns-discovery 

[Install]
WantedBy=multi-user.target
EOF



echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: IPA"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

echo "--------------------------------------------------------------"
echo "CannyOS: IPA: Config"
echo "--------------------------------------------------------------"
# Set the IP address for FreeIPA to store as its DNS address (this should be resolveable from putside the cluster)
IPA_SERVER_DEV=eth0
IPA_SERVER_IP=$(ip -f inet -o addr show $IPA_SERVER_DEV | cut -d\  -f 7 | cut -d/ -f 1)

# Set the DNS server for the ipa server to use
DNS_NAMESERVER=8.8.8.8

# Set the hostname for the master ipa server
IPA_HOSTNAME=ipa.cannyos.local


# Set the initial admin password for the IPA server
IPA_PASSWORD=Password123

# Set the name to give the ipa server container
IPA_SERVER_NAME=ipa_server


echo "--------------------------------------------------------------"
echo "CannyOS: IPA: Server Service"
echo "--------------------------------------------------------------"

cat > /etc/systemd/system/cannyos-ipa-server.service << EOF
[Unit]
Description=CannyOS: IPA Server Service
Documentation=http://git.cannycomputing.com/IPA/freeipa/wikis/home
After=docker.service etcd.service
Requires=docker.service etcd.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker pull cannyos/ipa_server
ExecStartPre=-/usr/bin/docker kill $IPA_SERVER_NAME
ExecStartPre=-/usr/bin/docker rm $IPA_SERVER_NAME
ExecStartPre=/var/usrlocal/bin/cannyos-ipa-server-start
ExecStart=/usr/bin/docker logs -f $IPA_SERVER_NAME
ExecStop=/var/usrlocal/bin/cannyos-ipa-server-stop

[Install]
WantedBy=multi-user.target
EOF


echo "--------------------------------------------------------------"
echo "CannyOS: IPA: Server Service: Start Script"
echo "--------------------------------------------------------------"

cat > /var/usrlocal/bin/cannyos-ipa-server-start << EOF
#!/bin/bash
# Inform the service monitor that we are initialising
IPA_STATUS="init"
etcdctl set /cannyos/config/ipa/status \$IPA_STATUS

# This will be defined by kickstart or cloud-init
IPA_SERVER_IP=$IPA_SERVER_IP
IPA_SERVER_NAME=$IPA_SERVER_NAME


echo "------------------------------------------"
echo "CannyOS: IPA: Data Container"
echo "------------------------------------------"

IPA_SERVER_DATA_NAME=$( echo $IPA_SERVER_NAME )_data
# Check to see if an IPA data container already exists
if docker inspect $IPA_SERVER_DATA_NAME ; then
  echo "CannyOS: IPA Server data container exists"
else
  echo "CannyOS: IPA Server data container deos not exist: creating"
  docker run \
  --name $IPA_SERVER_DATA_NAME \
  -v /data \
  cannyos/centos sh
fi

echo "------------------------------------------"
echo "CannyOS: IPA: Server Launch"
echo "------------------------------------------"

# Check to see if an IPA server container already exists
if docker inspect \$IPA_SERVER_NAME ; then
  echo "CannyOS: IPA Server container exists: attempting to start"
  docker start \$IPA_SERVER_NAME
else
  echo "CannyOS: IPA Server does not exist: attempting to create"
  docker run -d \
  --name \$IPA_SERVER_NAME \
  --dns $DNS_NAMESERVER \
  --volumes-from=\$IPA_SERVER_DATA_NAME \
  -h $IPA_HOSTNAME \
  -p 443:443 \
  -p 88:88/tcp \
  -p 88:88/udp \
  -p 389:389/tcp \
  -p 464:464/udp \
  -p 464:464/tcp \
  -e IPA_SERVER_IP=\$IPA_SERVER_IP \
  -e PASSWORD=$IPA_PASSWORD \
  cannyos/ipa_server
fi


echo "------------------------------------------"
echo "CannyOS: IPA: Initial Monitoring"
echo "------------------------------------------"

# Get the hostname from docker
IPA_HOSTNAME=\$(docker inspect --format='{{.Config.Hostname}}' \$IPA_SERVER_NAME).\$(docker inspect --format='{{.Config.Domainname}}' \$IPA_SERVER_NAME)

# Todo - sanity check that docker reports the same hostname that we set it

# Get the ip address of the ipa-server from docker
IPA_IP=\$(docker inspect --format='{{.NetworkSettings.IPAddress}}' \$IPA_SERVER_NAME )

# Wait for DNS Resolution to start working
DNS_RESPONSE=\$(dig @\$IPA_IP \$IPA_HOSTNAME | awk '/ANSWER SECTION/ { getline; print }' | awk -F' ' '{print \$5}')
while [ "\$DNS_RESPONSE" != "\$IPA_SERVER_IP" ]; do
  DNS_RESPONSE=\$(dig @\$IPA_IP \$IPA_HOSTNAME | awk '/ANSWER SECTION/ { getline; print }' | awk -F' ' '{print \$5}')
  sleep 1s
done


echo "------------------------------------------"
echo "CannyOS: IPA: Monitoring Handover"
echo "------------------------------------------"

# Update the cluster registry with our info
etcdctl mk /cannyos/config/ipa/ip \$IPA_IP || etcdctl update /cannyos/config/ipa/ip \$IPA_IP
etcdctl mk /cannyos/config/ipa/public_ip \$IPA_SERVER_IP || etcdctl update /cannyos/config/ipa/public_ip \$IPA_SERVER_IP
etcdctl mk /cannyos/config/ipa/hostname \$IPA_HOSTNAME || etcdctl update /cannyos/config/ipa/hostname \$IPA_HOSTNAME

# Inform the service monitor that we are ready
IPA_STATUS="ready"
etcdctl mk /cannyos/config/ipa/status \$IPA_STATUS || etcdctl update /cannyos/config/ipa/status \$IPA_STATUS

EOF
chmod +x /var/usrlocal/bin/cannyos-ipa-server-start


echo "--------------------------------------------------------------"
echo "CannyOS: IPA: Server Service: Stop Script"
echo "--------------------------------------------------------------"

cat > /var/usrlocal/bin/cannyos-ipa-server-stop << EOF
#!/bin/bash

# Inform the service monitor that we are down
IPA_STATUS="down"
etcdctl set /cannyos/config/ipa/status \$IPA_STATUS

# Stop the Server
docker stop $IPA_SERVER_NAME

EOF
chmod +x /var/usrlocal/bin/cannyos-ipa-server-stop




echo "--------------------------------------------------------------"
echo "CannyOS: IPA: Monitor: Service"
echo "--------------------------------------------------------------"
cat > /etc/systemd/system/cannyos-ipa-monitor.service << EOF
[Unit]
Description=CannyOS: IPA Service Monitor
After=etcd.service
Requires=etcd.service

[Service]
TimeoutStartSec=0
ExecStart=/var/usrlocal/bin/cannyos-ipa-monitor

[Install]
WantedBy=multi-user.target
EOF


echo "--------------------------------------------------------------"
echo "CannyOS: IPA: Monitor: Script"
echo "--------------------------------------------------------------"
cat > /var/usrlocal/bin/cannyos-ipa-monitor << EOF
#!/bin/sh

#Check the status of the IPA Service marking it as down if it dos not exist yet.
etcdctl get /cannyos/config/ipa/status || etcdctl mk /cannyos/config/ipa/status down

while true
do
  IPA_STATUS=\$(etcdctl get /cannyos/config/ipa/status)

  if [ "\$IPA_STATUS" != "ready" ]; then
    echo "CannyOS: IPA: DOWN"

    echo "CannyOS: Setting SkyDNS Forwarders"
    etcdctl set /skydns/config "{\"dns_addr\":\"0.0.0.0:53\",\"ttl\":3600, \"nameservers\": [\"8.8.8.8:53\"]}"

  elif [ "\$IPA_STATUS" == "ready" ]; then
    echo "CannyOS: IPA: READY"

    IPA_IP=\$(etcdctl get /cannyos/config/ipa/ip)
    IPA_HOSTNAME=\$(etcdctl get /cannyos/config/ipa/hostname)
    IPA_SERVER_IP=\$(etcdctl get /cannyos/config/ipa/public_ip)

    echo "CannyOS: IPA: Waiting for DNS resolution to work @\$IPA_IP for \$IPA_HOSTNAME to return \$IPA_SERVER_IP"
    # Wait for DNS Resolution to start working
    DNS_RESPONSE=\$(dig @\$IPA_IP \$IPA_HOSTNAME | awk '/ANSWER SECTION/ { getline; print }' | awk -F' ' '{print \$5}')
    while [ "\$DNS_RESPONSE" != "\$IPA_SERVER_IP" ]; do
      DNS_RESPONSE=\$(dig @\$IPA_IP \$IPA_HOSTNAME | awk '/ANSWER SECTION/ { getline; print }' | awk -F' ' '{print \$5}')
      sleep 1s
    done

    echo "CannyOS: Setting SkyDNS Forwarders to the IPA server @\$IPA_IP"
    etcdctl set /skydns/config "{\"dns_addr\":\"0.0.0.0:53\",\"ttl\":3600, \"nameservers\": [\"\$IPA_IP:53\"]}"

  fi

  echo "CannyOS: Restarting SkyDNS"
  systemctl restart skydns.service

  echo "CannyOS: SkyDNS restarted"
  #systemctl status skydns.service
  
  echo "CannyOS: Waiting on Service Status Update"
  etcdctl watch /cannyos/config/ipa/status

done
EOF
chmod +x /var/usrlocal/bin/cannyos-ipa-monitor



echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: OpenStack AIO"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

cat > /etc/systemd/system/canny-openstack-aio.service << EOF
[Unit]
Description=CannyOS: OpenStack AIO Service
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
ExecStartPre=-/usr/bin/docker pull cannyos/openstack-manager
ExecStartPre=/usr/bin/docker run --rm \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /root/canny:/root/canny \
    cannyos/openstack-manager pull
ExecStartPre=/usr/bin/docker run -rm \
    --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /root/canny:/root/canny \
    cannyos/openstack-manager start
ExecStart=/usr/bin/docker run --rm -t \
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
echo "CannyOS: Enable Services"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

systemctl enable canny-docker-storage

systemctl mask NetworkManager
systemctl enable ntpd

systemctl enable etcd.service
systemctl enable skydns.service
systemctl enable cannyos-dns-discovery

systemctl enable cannyos-ipa-monitor


# Master node specific
#systemctl enable cannyos-ipa-server
#systemctl enable cockpit.socket


echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Cleanup"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

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