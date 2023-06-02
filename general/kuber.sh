#!/bin/bash
set -eo pipefail

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/ s%/swap%#/swap%g' /etc/fstab

# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure kernel parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

sudo apt-get update && apt install -y apt-transport-https ca-certificates curl gnupg lsb-release


mkdir /etc/apt/keyrings/
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg


echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

sudo sed -i 's/ExecStart=\/usr\/bin\/kubelet/Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=\/etc\/kubernetes\/bootstrap-kubelet.conf --kubeconfig=\/etc\/kubernetes\/kubelet.conf --cgroup-driver=cgroupfs"/' /lib/systemd/system/kubelet.service

systemctl daemon-reload && systemctl restart kubelet



kubeadm config print init-defaults  > kubeadm-config.yaml

echo "okey!!! please edit kubeadm-config.yaml and run kubeadm init --config kubeadm-config.yaml"