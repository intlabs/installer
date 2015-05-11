#!/bin/bash

DISTRO=dban

wget $DBAN_ISO_URL

sudo mkdir -p /mnt/$DISTRO
sudo mount -o loop $DBAN_ISO  /mnt/$DISTRO

mkdir -p $BUILD_ROOT/assets/$DISTRO/pxeboot/
cp /mnt/$DISTRO/dban.bzi  $BUILD_ROOT/assets/$DISTRO/pxeboot/ && ls -lah $BUILD_ROOT/assets/$DISTRO/pxeboot/

chmod -R 755 $BUILD_ROOT/assets/$DISTRO

sudo umount /mnt/$DISTRO

rm -rf $DBAN_ISO
