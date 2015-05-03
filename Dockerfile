FROM ubuntu:14.04

MAINTAINER Pete Birley

# Install deps
RUN apt-get update && apt-get install -y dnsmasq syslinux wget

COPY app /app

# Install pxelinux.0
RUN mkdir app/tftp && cp /usr/lib/syslinux/pxelinux.0 /app/tftp

ADD http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz /app/tftp/coreos_production_pxe.vmlinuz
ADD http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz /app/tftp/coreos_production_pxe_image.cpio.gz

ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2 /config/images/633.1.0/coreos_production_image.bin.bz2
ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2.sig /config/images/633.1.0/coreos_production_image.bin.bz2.sig

RUN chmod 644 /app/tftp/coreos_production_pxe.vmlinuz && \
    chmod 644 /app/tftp/coreos_production_pxe_image.cpio.gz

CMD /app/init
