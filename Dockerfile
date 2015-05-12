FROM cannyos/centos

MAINTAINER Pete Birley

# Install deps
RUN yum install -y dnsmasq && \
    yum install -y syslinux && \
    yum install -y tftp-server && \
    yum install -y epel-release && \
    yum install -y nginx && \
    yum install -y createrepo && \
    yum install -y wget

ENV TFTP_BOOT /var/lib/tftpboot
ENV HTTP_ROOT /usr/share/nginx/html

# Moving the dnsmasq.conf out of the way so we dont accidentally use it later
RUN echo "CannyOS: moving the orginal dnsmasq.conf out of the way so we dont accidentally use it later" && \
    mv /etc/dnsmasq.conf  /etc/dnsmasq.conf.backup && \
    echo "CannyOS: Copying syslinux files to $TFTP_BOOT" && \
    cp -r /usr/share/syslinux/* $TFTP_BOOT


# Adding our nginx config
ADD assets/nginx.conf /etc/nginx/nginx.conf
# Adding the theme
ADD http://git.cannycomputing.com/Bedrock/Theme/raw/master/Graphics/Backgrounds/install/splash.png $TFTP_BOOT/splash.png

# Setting up pxe boot menu
RUN mkdir -p $TFTP_BOOT/pxelinux.cfg
ADD assets/pxelinux.cfg/default $TFTP_BOOT/pxelinux.cfg/default

# Adding dban kernel
ADD assets/dban/pxeboot/ $TFTP_BOOT/dban/

# Adding centos 7 kernel and ramdisk
ADD http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/initrd.img $TFTP_BOOT/centos7/initrd.img
ADD http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/upgrade.img $TFTP_BOOT/centos7/upgrade.img
ADD http://mirror.centos.org/centos/7/os/x86_64/images/pxeboot/vmlinuz $TFTP_BOOT/centos7/vmlinuz


# Adding coreos kernel and ramdisk
ADD http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz $TFTP_BOOT/coreos/
ADD http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz $TFTP_BOOT/coreos/
ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2 $HTTP_ROOT/coreos/633.1.0/
ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2.sig $HTTP_ROOT/coreos/633.1.0/
ADD http://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso $TFTP_BOOT/iso/coreos_production_iso_image.iso

# Adding Ubuntu Snappy
#ADD http://releases.ubuntu.com/15.04/ubuntu-15.04-snappy-amd64+generic.img.xz $HTTP_ROOT/ubuntu-snappy/ubuntu-15.04-snappy-amd64+generic.img.xz

# Adding Fedora 21
#ADD http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/os/isolinux/vmlinuz $TFTP_BOOT/fedora21/vmlinuz
#ADD http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/fedora/linux/releases/21/Server/x86_64/os/isolinux/initrd.img $TFTP_BOOT/fedora21/initrd.img

# Adding Fedora Atomic Host
#ADD http://download.fedoraproject.org/pub/fedora/linux/releases/test/22_Beta/Cloud/x86_64/Images/Fedora-Cloud-Atomic-22_Beta-20150415.x86_64.raw.xz $HTTP_ROOT/fedora-atomic/fedora-cloud-atomic.x86_64.raw.xz

# Adding Canny Atomic Host
#ADD https://s3-eu-west-1.amazonaws.com/cannyos-atomic/cannyos-atomic-host/7/images/cannyos-atomic-host-7.raw.xz $HTTP_ROOT/cannyos/cannyos.x86_64.raw.xz

# Adding centos 7 images
ADD http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1503.raw.xz $HTTP_ROOT/centos/images/centos.x86_64.raw.xz

# Adding Fedora images
ADD http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/Fedora-Cloud-Base-20141203-21.x86_64.raw.xz $HTTP_ROOT/fedora/images/fedora.x86_64.raw.xz

# Adding kickstarts
ADD assets/ks/ $HTTP_ROOT/ks/

# Adding cloudconfig
ADD assets/cloudconfig/ $HTTP_ROOT/cloudconfig/

RUN find $TFTP_BOOT -type d -exec chmod 755 {} \; && \
    find $TFTP_BOOT -type f -exec chmod 755 {} \; && \
    find $HTTP_ROOT -type d -exec chmod 755 {} \; && \
    find $HTTP_ROOT -type f -exec chmod 755 {} \;

ADD start.sh /start.sh
RUN chmod +x /start.sh
CMD /start.sh
