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

# Adding kickstarts
ADD assets/ks/ $HTTP_ROOT/ks/

# Adding cloudconfig
#ADD assets/cloudconfig/ $HTTP_ROOT/cloudconfig/
RUN mkdir -p $HTTP_ROOT/cloudconfig

RUN find $TFTP_BOOT -type d -exec chmod 755 {} \; && \
    find $TFTP_BOOT -type f -exec chmod 755 {} \; && \
    find $HTTP_ROOT -type d -exec chmod 755 {} \; && \
    find $HTTP_ROOT -type f -exec chmod 755 {} \;

ADD start.sh /start.sh
RUN chmod +x /start.sh
CMD /start.sh
