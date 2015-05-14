text
keyboard --vckeymap=us --xlayouts='gb'
lang en_US.UTF-8
timezone Etc/UTC --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

auth --useshadow --enablemd5
selinux --enforcing
rootpw --lock --iscrypted locked
#sshkey --username=root "ssh key"
user --groups=wheel --name=cannyos --password=password --gecos="cannyos"
firewall --disabled

bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"
network --bootproto=dhcp --device=eth0 --activate --onboot=on

services --enabled=sshd,rsyslog,cloud-init,cloud-init-local,cloud-config,cloud-final
# We use NetworkManager, and Avahi doesn't make much sense in the cloud
services --disabled=network,avahi-daemon

zerombr
clearpart --all
part /boot --size=300 --fstype="xfs"
part pv.01 --grow
volgroup atomicos pv.01
logvol / --size=3000 --fstype="xfs" --name=root --vgname=atomicos
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
# remove the user anaconda forces us to make
#userdel -r cannyos

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
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF



# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .


# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot









echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: ETCD configuration"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

export NODE_IP=$ETH0_IP
cat > /etc/etcd/etcd.conf << EOF
# [member]
ETCD_NAME=$NODE_IP
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#ETCD_SNAPSHOT_COUNTER="10000"
#ETCD_HEARTBEAT_INTERVAL="100"
#ETCD_ELECTION_TIMEOUT="1000"
ETCD_LISTEN_PEER_URLS="http://$NODE_IP:2380,http://$NODE_IP:7001"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:2379,http://$NODE_IP:4001"
#ETCD_MAX_SNAPSHOTS="5"
#ETCD_MAX_WALS="5"
#ETCD_CORS=""
#
#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$NODE_IP:2380,http://$NODE_IP:7001"
# if you use different ETCD_NAME (e.g. test), set ETCD_INITIAL_CLUSTER value for this name, i.e. "test=http://..."
#ETCD_INITIAL_CLUSTER="default=http://localhost:2380,default=http://localhost:7001"
#ETCD_INITIAL_CLUSTER_STATE="new"
#ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
#ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379,http://localhost:4001"
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
ExecStart=/usr/bin/etcd \
  -name \${ETCD_NAME} \
  -initial-advertise-peer-urls \${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
  -listen-peer-urls \${ETCD_LISTEN_PEER_URLS} \
  -listen-client-urls \${ETCD_LISTEN_CLIENT_URLS} \
  -discovery \${ETCD_DISCOVERY}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF









echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Flanneld networking configuration"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

cat > /etc/sysconfig/flanneld-conf.json << EOF
{
  "Network": "10.96.0.0/12",
  "SubnetLen": 24,
  "Backend": {
    "Type": "vxlan"
  }
}
EOF

cat > /etc/systemd/system/flanneld-conf.service << EOF
[Unit]
Description=CannyOS: Flanneld Configuration
After=etcd.service

[Service]
TimeoutStartSec=0
Type=oneshot
User=root
ExecStartPre=/bin/bash -c "while ! echo 'CannyOS: ETCD now up' | nc 127.0.0.1 4001; do sleep 1; done"
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
#FLANNEL_OPTIONS=""
EOF

cat > /etc/systemd/system/flanneld.path << EOF
[Path]
PathExists=/run/flannel/subnet.env
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
EnvironmentFile=/run/flannel/subnet.env
ExecStartPre=-/usr/sbin/ip link del docker0
ExecStart=
ExecStart=/usr/bin/docker -d --bip=\${FLANNEL_SUBNET} --mtu=\${FLANNEL_MTU} \$OPTIONS \$DOCKER_STORAGE_OPTIONS
EOF









echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "CannyOS: Cleanup"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"


echo "Removing random-seed so it's not the same in every image."
rm -f /var/lib/random-seed

echo "Packages within this cloud image:"
echo "-----------------------------------------------------------------------"
rpm -qa
echo "-----------------------------------------------------------------------"
# Note that running rpm recreates the rpm db files which aren't needed/wanted
rm -f /var/lib/rpm/__db*

%end