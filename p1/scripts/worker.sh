#!/bin/bash
set -e

export INSTALL_K3S_VERSION="v1.28.8+k3s1"
export K3S_URL="https://192.168.56.110:6443"
export K3S_TOKEN=$(cat /vagrant/node-token)
export INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=enp0s8"

curl -sfL https://get.k3s.io | sh -