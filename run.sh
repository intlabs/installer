#!/bin/bash 

#docker run --net=host -e INTERFACE=enp3s0 cannyos/installer

#docker run -it --rm --privileged --net=host -e INTERFACE=eth1 cannyos/installer
SSH_PUBLIC_KEY=$(echo $(cat /root/.ssh/id_rsa.pub))
git stash && git pull && \
docker build -t "cannyos/installer" $(pwd) && \
docker run -it --rm --privileged --net=host -e INTERFACE=eth1 -e SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" cannyos/installer


#docker run -d -p 8000:80 cannyos/atomicrepo