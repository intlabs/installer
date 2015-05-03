FROM ubuntu:14.04

MAINTAINER Pete Birley

# Install deps
RUN apt-get update && apt-get install -y dnsmasq syslinux wget

COPY app /app

# Install pxelinux.0
RUN mkdir app/tftp && cp /usr/lib/syslinux/pxelinux.0 /app/tftp

# Install coreos pxe images
RUN cd /app/tftp && \
    wget -q http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz && \
    wget -q http://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz


CMD /app/init
