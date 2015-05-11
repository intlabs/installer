#!/bin/bash
set -e

CONTAINER_NAME="cannyos/installer_configdrive"

BUILD_PATH=$(dirname $0)

# Build base container image
sudo docker build -t="$CONTAINER_NAME" $BUILD_PATH

mkdir -p ~/docker
touch ~/docker/pushlist
echo "$CONTAINER_NAME" >> ~/docker/pushlist
