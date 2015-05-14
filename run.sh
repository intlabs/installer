#!/bin/bash 

#docker run --net=host -e INTERFACE=enp3s0 cannyos/installer
export REPO_PORT=8012
export INSTALLER_PORT=8013
export IMAGES_PORT=8014


docker run -d -p $REPO_PORT:80 cannyos/atomic_dist_rpmostree
docker run -d -p $INSTALLER_PORT:80 cannyos/atomic_dist_installer:stable



git stash && git pull && \
docker build -t "cannyos/installer" $(pwd) && \
SWARM_TOKEN=$( docker run --rm swarm create ) && \
SSH_PUBLIC_KEY=$(echo $(cat /root/.ssh/id_rsa.pub)) && \
docker run -it --rm --privileged \
--net=host \
-e INTERFACE=eth1 \
-e SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
-e REPO_PORT="$REPO_PORT" \
-e INSTALLER_PORT="$INSTALLER_PORT" \
-e SWARM_TOKEN="$SWARM_TOKEN" \
cannyos/installer
