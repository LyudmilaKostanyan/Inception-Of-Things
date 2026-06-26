#!/bin/bash
set -e
export INSTALL_K3S_VERSION="v1.28.8+k3s1"
export INSTALL_K3S_EXEC="--bind-address=192.168.56.110 \
  --advertise-address=192.168.56.110 \
  --node-ip=192.168.56.110 \
  --flannel-iface=enp0s8 \
  --write-kubeconfig-mode 644"
curl -sfL https://get.k3s.io | sh -
chmod 644 /var/lib/rancher/k3s/server/node-token
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
