#!/bin/bash 

#docker run --net=host -e INTERFACE=enp3s0 cannyos/installer

#docker run -it --rm --privileged --net=host -e INTERFACE=eth1 cannyos/installer
git stash && git pull && \
docker build -t "cannyos/installer" $(pwd) && \
docker run -it --rm --privileged --net=host -e INTERFACE=eth1 cannyos/installer


#docker run -d -p 8000:80 cannyos/atomicrepo