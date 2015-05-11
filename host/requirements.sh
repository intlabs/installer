#!/bin/bash

sudo yum install -y wget git docker && \
sudo systemctl enable docker && \
sudo systemctl start docker
