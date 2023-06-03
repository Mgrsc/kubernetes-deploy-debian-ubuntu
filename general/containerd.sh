#!/bin/bash

# Enable strict mode and error handling
set -eo pipefail

# Install packages using apt-get
install_package() {
  sudo apt-get install -y "$@"
}

# Download a file from a URL and save it locally
download_file() {
  local url="$1"     # URL of file to download
  local dest="$2"    # Local destination of the file
  if [ ! -f "${dest}" ]; then  # If file does not exist locally, download it
    wget "${url}" -O "${dest}"
  fi
}

# Remove a local file
remove_file() {
  local file="$1"   # File to remove
  if [ -f "${file}" ]; then   # If file exists, remove it
    rm -rf "${file}"
    echo "${file} has been deleted!"
  fi
}

check_installed() {
  if [ -f "$1" ]; then
    echo "$2 has been installed successfully!"
  else
    echo "$2 not installed"
  fi
}



# Install required packages
install_package jq wget

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Enable kernel modules required for Kubernetes
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Enable IP forwarding and netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Download and install containerd
CONTAINERD_TAR=`ls | grep containerd-.*linux-amd64.tar.gz`
if [ "$CONTAINERD_TAR" != "" ]; then    # If containerd tar file exists locally, extract it
  sudo tar xzvf "${CONTAINERD_TAR}" -C /usr/local
else                                       # Otherwise, download the latest release
  LATEST_CONTAINERD=$(curl --silent "https://api.github.com/repos/containerd/containerd/releases/latest" | jq -r .tag_name)
  CONTAINERD_URL="https://github.com/containerd/containerd/releases/download/${LATEST_CONTAINERD}/containerd-${LATEST_CONTAINERD#v}-linux-amd64.tar.gz"
  CONTAINERD_TAR="containerd-${LATEST_CONTAINERD#v}-linux-amd64.tar.gz"
  download_file "${CONTAINERD_URL}" "${CONTAINERD_TAR}"
  sudo tar xzvf "${CONTAINERD_TAR}" -C /usr/local
fi

# Install the containerd service file and start containerd
CONTAINERD_SERVICE_DEST="/etc/systemd/system/containerd.service"
if [ -f containerd.service ]; then  
  sudo cp containerd.service "${CONTAINERD_SERVICE_DEST}"
  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd
else                                          # Otherwise, download the service file and start containerd
  CONTAINERD_SERVICE_URL="https://raw.githubusercontent.com/containerd/containerd/main/containerd.service"
  download_file "${CONTAINERD_SERVICE_URL}" "${CONTAINERD_SERVICE_DEST}"
  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd
fi

# Download and install runc
RUNC_DEST="runc.amd64"
if [ -f "$RUNC_DEST" ]; then
  sudo install -m 755 "$RUNC_DEST" /usr/local/sbin/runc 
else
  LATESTRUNC=$(curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | jq -r .tag_name)
  URLRUNC="https://github.com/opencontainers/runc/releases/download/${LATESTRUNC}/runc.amd64"
  download_file "${URLRUNC}" "${RUNC_DEST}"
  sudo install -m 755 "$RUNC_DEST" /usr/local/sbin/runc
fi

# Install CNI plugins
CNI_TAR=$(ls cni-plugins-linux-amd64-*.tgz 2>/dev/null)
if [ -n "$CNI_TAR" ]; then
  LATESTCNI=$(echo "$CNI_TAR" | sed 's/cni-plugins-linux-amd64-\(.*\).tgz/\1/')
  mkdir -p /opt/cni/bin
  sudo tar xzf "cni-plugins-linux-amd64-${LATESTCNI}.tgz" -C /opt/cni/bin
else
  LATESTCNI=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | jq -r .tag_name)    
  URLCNI="https://github.com/containernetworking/plugins/releases/download/${LATESTCNI}/cni-plugins-linux-amd64-${LATESTCNI}.tgz"
  CNI_TAR="cni-plugins-linux-amd64-${LATESTCNI}.tgz"
  download_file "${URLCNI}" "${CNI_TAR}"
  mkdir -p /opt/cni/bin 
  sudo tar xzf "$CNI_TAR" -C /opt/cni/bin  
fi

check_installed "/usr/local/bin/containerd" "containerd ${VERSION} install access"
sleep 1
check_installed "/etc/systemd/system/containerd.service" "containerd service access"
sleep 1
check_installed "/usr/local/sbin/runc" "runc ${LATESTRUNC}"
sleep 1
check_installed "/opt/cni/bin/dhcp" "cni-plugins ${LATESTCNI}"


# Update containerd configuration
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's%registry.k8s.io/pause:3.8%registry.aliyuncs.com/google_containers/pause:3.9%g' /etc/containerd/config.toml
sudo sed -i 's%SystemdCgroup = false%SystemdCgroup = true%g' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl restart containerd

# Create a config for crictl
sudo tee /etc/crictl.yaml > /dev/null <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF

# Ask if downloaded files should be removed and take action
echo "Download completed! Do you want to remove downloaded files? (y/n)"
read answer
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
  remove_file "${CONTAINERD_TAR}"
  remove_file "${RUNC_DEST}"
  remove_file "${CNI_TAR}"
  remove_file "containerd.service"
else
  echo "Downloaded files are not removed!"
fi



echo "containerd ${LATEST_CONTAINERD} installation completed"