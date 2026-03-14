#!/bin/bash

set -e

echo "===== Loading Kernel Modules ====="

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


echo "===== Setting Kubernetes Networking ====="

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

sudo sysctl --system


echo "===== Installing Containerd ====="

sudo apt-get update
sudo apt-get install -y containerd


echo "===== Configuring Containerd ====="

sudo mkdir -p /etc/containerd

sudo containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemd cgroup driver (required for Kubernetes)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd


echo "===== Disabling Swap ====="

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab


echo "===== Installing Kubernetes Dependencies ====="

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg


echo "===== Adding Kubernetes Repository (v1.34) ====="

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list


echo "===== Installing Kubernetes Components ====="

sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl


echo "===== Enabling kubelet ====="

sudo systemctl enable kubelet


echo "===== Installation Complete ====="

echo "Next step (Master Node):"
echo "sudo kubeadm init --pod-network-cidr=192.168.0.0/16"

