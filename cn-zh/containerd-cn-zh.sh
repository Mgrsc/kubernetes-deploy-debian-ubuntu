#!/bin/bash
set -eo pipefail

# Install required packages
sudo apt-get install -y jq wget sudo

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

# Download and install containerd
LATEST=$(curl --silent "https://api.github.com/repos/containerd/containerd/releases/latest" | jq -r .tag_name)
URL="https://github.com/containerd/containerd/releases/download/${LATEST}/containerd-${LATEST#v}-linux-amd64.tar.gz"
wget "${URL}"
sudo tar xzvf "containerd-${LATEST#v}-linux-amd64.tar.gz" -C /usr/local

# Download and enable containerd systemd service
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /etc/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Install runc
LATESTRUNC=$(curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | jq -r .tag_name)
URLRUNC="https://github.com/opencontainers/runc/releases/download/${LATESTRUNC}/runc.amd64"
wget "${URLRUNC}"
sudo install -m 755 runc.amd64 /usr/local/sbin/runc


# Install CNI plugins
LATESTCNI=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | jq -r .tag_name)
URLCNI="https://github.com/containernetworking/plugins/releases/download/${LATESTCNI}/cni-plugins-linux-amd64-${LATESTCNI}.tgz"
wget "${URLCNI}"
mkdir -p /opt/cni/bin
sudo tar xzvf "cni-plugins-linux-amd64-${LATESTCNI}.tgz" -C /opt/cni/bin


# Check installation
if [ -f "/usr/local/bin/containerd" ]; then
  echo "containerd ${LATEST} install access"
else
  echo "containerd ${LATEST} not installed"
fi

if [ -f "/etc/systemd/system/containerd.service" ]; then
  echo "containerd service access"
else
  echo "/etc/systemd/system/containerd.service not found"
fi

if [ -f "/usr/local/sbin/runc" ]; then
  echo "runc ${LATESTRUNC} has been installed successfully!"
else
  echo "runc ${LATESTRUNC} has been installed fail !!!!!!!"
fi

if [ -f "/opt/cni/bin/dhcp" ]; then
  echo "cni-plugins ${LATESTCNI} has been installed successfully!"
else
  echo "cni-plugins ${LATESTCNI} has been installed fail !!!!!!"
fi


# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml  >/dev/null 2>&1
str1="registry.k8s.io/pause:3.8"
str2="registry.aliyuncs.com/google_containers/pause:3.9"
sed -i "/sandbox_image/ s%${str1}%${str2}%g" /etc/containerd/config.toml
sed -i '/SystemdCgroup/ s/false/true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Configure crictl
sudo tee /etc/crictl.yaml > /dev/null <<EOF
pull-image-on-create: false
disable-pull-on-run: false
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF



# Download and install kubectl
DOWNLOAD_DIR="${HOME}"
echo "Download completed! Do you want to remove downloaded files? (y/n)"
read answer
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
  if [ -f "${DOWNLOAD_DIR}/containerd-${LATEST#v}-linux-amd64.tar.gz" ]; then
    rm -rf  "${DOWNLOAD_DIR}/containerd-${LATEST#v}-linux-amd64.tar.gz"
    echo "containerd-${LATEST#v}-linux-amd64.tar.gz has been deleted!"
  fi

  if [ -f "${DOWNLOAD_DIR}/runc.amd64" ]; then
    rm -rf "${DOWNLOAD_DIR}/runc.amd64"
    echo "runc.amd64 has been deleted!"
  fi
  
  if [ -f "${DOWNLOAD_DIR}/cni-plugins-linux-amd64-${LATESTCNI}.tgz" ]; then
    rm -rf "${DOWNLOAD_DIR}/cni-plugins-linux-amd64-${LATESTCNI}.tgz"
    echo "cni-plugins-linux-amd64-${LATESTCNI}.tgz has been deleted!"
  fi
else
  echo "okey"
fi


echo "containerd ${LATEST} install access"

