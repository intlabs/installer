#!/bin/bash

DISTRO=fedora-atomic

wget $FEDORA_ATOMIC_ISO_URL

sudo mkdir -p /mnt/$DISTRO
sudo mount -o loop $FEDORA_ATOMIC_ISO /mnt/$DISTRO

mkdir -p $BUILD_ROOT/assets/$DISTRO/pxeboot/
cp -r /mnt/$DISTRO/images/pxeboot/* $BUILD_ROOT/assets/$DISTRO/pxeboot/ && ls -lah $BUILD_ROOT/assets/$DISTRO/pxeboot/

mkdir -p $BUILD_ROOT/assets/$DISTRO/http
cp -r /mnt/$DISTRO/* $BUILD_ROOT/assets/$DISTRO/http/ && ls -lah $BUILD_ROOT/assets/$DISTRO/http/

chmod -R 755 $BUILD_ROOT/assets/$DISTRO

sudo umount /mnt/$DISTRO

rm -rf $FEDORA_ATOMIC_ISO
