#!/bin/bash 

docker run --net=host -e INTERFACE=enp3s0 cannyos/installer
