#!/bin/bash

#RAW_IMAGE_NAME="fedora-cloud-atomic.x86_64.raw"
#curl http://{{ SERVER_IP }}/fedora-atomic/$RAW_IMAGE_NAME.xz | xz -dc | sudo dd conv=sparse of=/dev/sda

echo "CannyOS: Installing CentOS to the first disc on this node"
RAW_IMAGE_NAME="centos.x86_64.raw"
curl http://{{ SERVER_IP }}/centos/images/$RAW_IMAGE_NAME.xz | xz -dc | sudo dd of=/dev/sda


echo "CannyOS: Generating this nodes cloud config"
CLOUD_CONFIG_TEMP="/tmp/cannyos-atomic-cloud-config"
mkdir -p $CLOUD_CONFIG_TEMP


echo "CannyOS: Cloud config default local hostname"
cat > $CLOUD_CONFIG_TEMP/meta-data << EOF
local-hostname: fedora-atomic-host
EOF

echo "CannyOS: Cloud config default settings for testing"
sudo cat > $CLOUD_CONFIG_TEMP/user-data << EOF
#cloud-config
password: fedora
chpasswd: { expire: False }
ssh_pwauth: True
lock-passwd: False
EOF

until sudo docker pull cannyos/installer_configdrive; do sleep 2; done

sudo docker run -v $CLOUD_CONFIG_TEMP:/configdrive cannyos/installer_configdrive

USB_KEY=$(
        grep -Hv ^0$ /sys/block/*/removable |
        sed s/removable:.*$/device\\/uevent/ |
        xargs grep -H ^DRIVER=sd |
        sed s/device.uevent.*$/size/ |
        xargs grep -Hv ^0$ |
        cut -d / -f 4
    )
CONFIG_DRIVE=$USB_KEY

echo "Config drive: $CONFIG_DRIVE"
sudo dd bs=4M if=$CLOUD_CONFIG_TEMP/cannyos-cloudinit-data.iso of=/dev/$CONFIG_DRIVE



sudo reboot
