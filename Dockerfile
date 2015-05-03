FROM ubuntu:14.04

MAINTAINER Pete Birley

# Install deps
RUN apt-get update && apt-get install -y dnsmasq syslinux wget

COPY app /app

# Install pxelinux.0
RUN mkdir app/tftp && cp /usr/lib/syslinux/pxelinux.0 /app/tftp

RUN cd /app/tftp && \
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz && \
    wget http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz

ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2 /config/images/
ADD http://stable.release.core-os.net/amd64-usr/633.1.0/coreos_production_image.bin.bz2.sig /config/images/

CMD /app/init
