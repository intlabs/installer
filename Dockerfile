FROM ubuntu:14.04

MAINTAINER Pete Birley

# Install deps
RUN apt-get update && apt-get install -y dnsmasq syslinux wget

COPY app /app

# Install pxelinux.0
RUN mkdir app/tftp && cp /usr/lib/syslinux/pxelinux.0 /app/tftp

#ADD http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz /app/tftp/coreos_production_pxe.vmlinuz
#ADD http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz /app/tftp/coreos_production_pxe_image.cpio.gz

#ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2 /config/images/633.1.0/coreos_production_image.bin.bz2
#ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2.sig /config/images/633.1.0/coreos_production_image.bin.bz2.sig

#RUN chmod 644 /app/tftp/coreos_production_pxe.vmlinuz && \
#    chmod 644 /app/tftp/coreos_production_pxe_image.cpio.gz


# wget http://mirror.ox.ac.uk/sites/mirror.centos.org/7/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso
# mount -o loop CentOS-7-x86_64-Minimal-1503-01.iso  /mnt
# mkdir -p ~/assets
# cp /mnt/images/pxeboot/vmlinuz  ~/assets
# cp /mnt/images/pxeboot/initrd.img  ~/assets
ADD assets/vmlinuz /app/tftp/vmlinuz
ADD assets/initrd.img /app/tftp/initrd.img

RUN chmod 644 /app/tftp/vmlinuz && \
    chmod 644 /app/tftp/initrd.img
CMD /app/init
