text
install
keyboard --vckeymap=us --xlayouts='gb'
lang en_US.UTF-8
timezone Etc/UTC --isUtc
auth --useshadow --enablemd5
#selinux --disabled
#firewall --disabled
services --enabled=NetworkManager,sshd
eula --agreed
ignoredisk --only-use=sda
reboot

bootloader --location=mbr
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=1024
part /boot --fstype xfs --size=200
part pv.01 --size=1 --grow
volgroup rootvg01 pv.01
logvol / --fstype xfs --name=lv01 --vgname=rootvg01 --size=1 --grow

# Root password
rootpw --plaintext r00tme

# Create default user
user --groups=wheel --name=user --plaintext --password=password


url --url="http://mirror.centos.org/centos/7/os/x86_64/"

%packages --nobase --ignoremissing
@core
%end

%post --erroronfail

setenforce 0

cat > /etc/sysconfig/selinux << EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#       enforcing - SELinux security policy is enforced.
#       permissive - SELinux prints warnings instead of enforcing.
#       disabled - SELinux is fully disabled.
SELINUX=disabled
# SELINUXTYPE= type of policy in use. Possible values are:
#       targeted - Only targeted network daemons are protected.
#       strict - Full SELinux protection.
SELINUXTYPE=targeted

# SETLOCALDEFS= Check local definition changes
SETLOCALDEFS=0
EOF

cat > /etc/yum.repos.d/atomic7-testing.repo << EOF
[atomic7-testing]
name=atomic7-testing
baseurl=http://cbs.centos.org/repos/atomic7-testing/x86_64/os/
gpgcheck=0
EOF

cat > /etc/yum.repos.d/virt7-testing.repo << EOF
[virt7-testing]
name=virt7-testing
baseurl=http://cbs.centos.org/repos/virt7-testing/x86_64/os/
gpgcheck=0
exclude=kernel
EOF

cat > /etc/yum.repos.d/openstack-kilo.repo << EOF
[openstack-kilo]
name=OpenStack Juno Repository
baseurl=http://repos.fedorapeople.org/repos/openstack/openstack-kilo/el7/
enabled=1
skip_if_unavailable=0
gpgcheck=0
EOF


yum install -y epel-release
yum update -y
yum remove -y docker
yum install -y wget ntp git tcpdump docker-master python-pip
yum install -y cockpit

echo "CannyOS: Installing requirements"

# Remove network manager
systemctl stop network && \
systemctl stop NetworkManager && \
systemctl disable NetworkManager && \
systemctl start network && \
systemctl enable network && \
systemctl status network

echo "Cannyos: Making life easier by dropping the firewall"
systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld

echo "Cannyos: starting docker service"
systemctl stop docker.service
systemctl enable docker.service
systemctl start docker.service
systemctl status docker.service

echo "CannyOS: starting cockpit service"
systemctl stop cockpit.service
systemctl start cockpit.service
systemctl enable cockpit.service
systemctl status cockpit.service

# Start NTP
systemctl start ntpd
systemctl enable ntpd


# Remove network manager
systemctl stop network && \
systemctl stop NetworkManager && \
systemctl disable NetworkManager && \
systemctl start network && \
systemctl enable network && \
systemctl status network

# Add vxlan kernel module for Neutron
modprobe vxlan


# Pull the openstack repo
git clone http://git.cannycomputing.com/user/compose-openstack.git /root/canny-openstack

%end
