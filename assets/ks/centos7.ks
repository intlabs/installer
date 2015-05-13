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
