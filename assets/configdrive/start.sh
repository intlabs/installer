#!/bin/sh

CONFIG_DRIVE_NAME="cannyos-cloudinit-data.iso"

cd /configdrive

echo "CannyOS: Generating Cloud Init Config Drive for Atomic Linux"
genisoimage -output /tmp/$CONFIG_DRIVE_NAME -volid cidata -joliet -rock user-data meta-data && \
rm -rf /configdrive

mv /tmp/$CONFIG_DRIVE_NAME /configdrive/$CONFIG_DRIVE_NAME
echo "CannyOS: Generating Cloud Init Config Drive created and saved as: $CONFIG_DRIVE_NAME"
