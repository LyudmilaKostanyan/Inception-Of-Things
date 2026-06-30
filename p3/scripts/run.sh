#!/bin/bash

set -e

echo "------Create cluster------"
k3d cluster create iot --wait
k3d kubeconfig merge iot -s

echo
echo "------Nodes------"
kubectl get nodes

echo
echo "------Create namespaces------"
kubectl create namespace argocd
kubectl create namespace dev

echo
echo "------Install Argo CD------"
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s

echo
echo "------Get Nodes------"
kubectl get pods -n argocd

