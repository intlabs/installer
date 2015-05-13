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
exclude=kernel,docker
EOF

yum install -y epel-release
yum update -y
yum install -y rpm-ostree-toolbox
yum install -y virt-manager xauth
yum install -y git
yum install -y cockpit

echo "CannyOS: Installing requirements"

echo "Cannyos: Making life asier by dropping the firewall"
systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld

echo "Cannyos: starting docker service"
systemctl stop docker.service
systemctl enable docker.service
systemctl start docker.service
systemctl status docker.service

echo "CannyOS: starting libvirt service"
systemctl stop libvirtd.service
systemctl start libvirtd.service
systemctl enable libvirtd.service
systemctl status libvirtd.service

echo "CannyOS: starting cockpit service"
systemctl stop cockpit.service
systemctl start cockpit.service
systemctl enable cockpit.service
systemctl status cockpit.service

%end
