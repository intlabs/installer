#!/bin/bash

set -e

CLOUD_CONFIG=coreos.yaml

# Fetch cloud-config
until curl -O http://{{ SERVER_IP }}/cloudconfig/$CLOUD_CONFIG; do sleep 2; done

NODE_MANAGEMENT_IP=$( ip route get {{ SERVER_IP }} | awk 'NR==1 {print $NF}' )
NODE_MANAGEMENT_IP_DASH=$(echo $NODE_MANAGEMENT_IP | tr "." "-" )

sed -i "s/{{ CLIENT_IP_DASH }}/$NODE_MANAGEMENT_IP_DASH/g" $CLOUD_CONFIG
sed -i "s/{{ CLIENT_IP }}/$NODE_MANAGEMENT_IP/g" $CLOUD_CONFIG

# Install coreos
until sudo coreos-install -d /dev/sda -c $CLOUD_CONFIG -b http://{{ SERVER_IP }}/coreos; do sleep 2; done

sudo reboot
