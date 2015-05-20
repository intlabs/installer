#!/bin/bash 



export REPO_PORT=8012
export INSTALLER_PORT=8013

docker run -d -p $REPO_PORT:80 cannyos/atomic_dist_rpmostree
docker run -d -p $INSTALLER_PORT:80 cannyos/atomic_dist_installer:stable



git stash && git pull && \
docker build -t "cannyos/installer" $(pwd)



#SWARM_TOKEN=$( docker run --rm swarm create ) && \

ETCD_DISCOVERY_TOKEN=$(wget -qO- https:\/\/discovery.etcd.io\/new?size=$ETCD_INITIAL_NODES) && \
SWARM_TOKEN=$ETCD_DISCOVERY_TOKEN
SSH_PUBLIC_KEY=$(echo $(cat /root/.ssh/id_rsa.pub))



PXECID=$(docker run -it --privileged \
        -e SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
        -e REPO_PORT="$REPO_PORT" \
        -e INSTALLER_PORT="$INSTALLER_PORT" \
        -e SWARM_TOKEN="$SWARM_TOKEN" \
        -e ETCD_INITIAL_NODES="1" \
        -e DHCP_START="10.40.0.10" \
        -e DHCP_END="10.40.255.255" \
        -e DHCP_NETMASK="255.255.0.0" \
        -e ETCD_DISCOVERY_TOKEN="$ETCD_DISCOVERY_TOKEN" \
        cannyos/installer )

~/pipework eth1 loving_curie 10.40.0.1/24
