#!/bin/bash

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Source: http://kubernetes.io/docs/getting-started-guides/kubeadm/

### setup terminal
apt-get install -y bash-completion binutils
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc

# ============================
# Variables
# ============================
KUBE_VERSION="1.29.0"  # Ensure this version exists in the Kubernetes repository
APISERVER_ADVERTISE_ADDRESS="192.168.4.100"
POD_NETWORK_CIDR="10.244.0.0/16"
CRICTL_VERSION="v1.32.0"
SSH_DIR="/home/vagrant/.ssh"
ROOT_SSH_DIR="/root/.ssh"
VAGRANT_USER="vagrant"
KUBE_JOIN_FILE="/vagrant/kubeadm-join-config.yaml"


# 1. Set up SSH for vagrant user
echo -e "${CYAN}Setting up SSH for vagrant user....${NC}"
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR
cat /vagrant/ssh/id_rsa.pub >> $SSH_DIR/authorized_keys
chmod 600 $SSH_DIR/authorized_keys

# Copy private key
cp /vagrant/ssh/id_rsa $SSH_DIR/id_rsa
chmod 600 $SSH_DIR/id_rsa

# 2. Set up SSH for root user
echo -e "${CYAN}Setting up SSH for root user...${NC}"
sudo mkdir -p $ROOT_SSH_DIR
sudo chmod 700 $ROOT_SSH_DIR
sudo cat /vagrant/ssh/id_rsa.pub >> $ROOT_SSH_DIR/authorized_keys
sudo chmod 600 $ROOT_SSH_DIR/authorized_keys

# Copy private key to root
sudo cp /vagrant/ssh/id_rsa $ROOT_SSH_DIR/id_rsa
sudo chmod 600 $ROOT_SSH_DIR/id_rsa

# 3. Configure SSH to disable StrictHostKeyChecking
echo -e "${CYAN}Configuring SSH...${NC}"
echo 'StrictHostKeyChecking no' >> $SSH_DIR/config
echo 'UserKnownHostsFile /dev/null' >> $SSH_DIR/config
chmod 600 $SSH_DIR/config

sudo bash -c "echo 'StrictHostKeyChecking no' >> $ROOT_SSH_DIR/config"
sudo bash -c "echo 'UserKnownHostsFile /dev/null' >> $ROOT_SSH_DIR/config"
sudo chmod 600 $ROOT_SSH_DIR/config

# 4. Update SSHD configuration
echo -e "${CYAN}Updating SSHD configuration...${NC}"
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 5. Set root password
echo -e "${CYAN}Setting root password....${NC}"
echo -e "r00tr00t\nr00tr00t" | sudo passwd root

# 6. Copy hosts file

echo -e "${CYAN}Copying hosts file...${NC}"
sudo cp /vagrant/hosts_vmware /etc/hosts


# ============================
# Remove Old Kubernetes and Docker Versions
# ============================
echo -e "${CYAN}Removing old Docker and Kubernetes packages....${NC}"
sudo apt-get remove -y docker.io kubelet kubeadm kubectl kubernetes-cni || true
sudo apt-get autoremove -y

# ============================
# Remove Existing Kubernetes Repositories
# ============================
echo -e "${CYAN}Removing any existing Kubernetes APT repositories..${NC}"
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

# ============================
# Load Required Kernel Modules
# ============================
echo -e "${CYAN}Loading required kernel modules..${NC}"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# ============================
# Disable Swap
# ============================
echo -e "${CYAN}Disabling swap..${NC}"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# ============================
# Apply Kernel Parameters
# ============================
echo -e "${CYAN}Applying kernel parameters for Kubernetes...${NC}"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# ============================
# Install Dependencies
# ============================
echo -e "${CYAN}Installing required packages....${NC}"
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    socat \
    net-tools \
    openssl

# ============================
# Install Containerd
# ============================
echo -e "${CYAN}Installing and configuring containerd....${NC}"
# Add Docker’s official GPG key and set up the stable repository
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index and install containerd and Docker packages
sudo apt-get update -y
sudo apt-get install -y \
    containerd.io \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin

# Configure containerd to use systemd as the cgroup driver
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# ============================
# Install crictl
# ============================
echo -e "${CYAN}Installing crictl...${NC}"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$CRICTL_VERSION-linux-amd64.tar.gz

# Verify crictl installation
crictl --version

# ============================
# Configure crictl
# ============================
echo -e "${CYAN}Configuring crictl...${NC}"
sudo tee /etc/crictl.yaml > /dev/null <<EOF
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# ============================
# Add Kubernetes Apt Repository
# ============================
echo -e "${CYAN}Adding Kubernetes APT repository for version ${KUBE_VERSION}...${NC}"
# Install kubeadm, kubelet and kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# ============================
# Install kubelet, kubeadm, kubectl
# ============================
echo -e "${CYAN}Installing kubelet, kubeadm, and kubectl...${NC}"
sudo apt-get update -y
sudo apt-get install -y \
    kubelet=${KUBE_VERSION}-1.1 \
    kubeadm=${KUBE_VERSION}-1.1 \
    kubectl=${KUBE_VERSION}-1.1

# Detect the 192.168.4.x IP
PUBLIC_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.168\.4\.' | head -n 1)

if [ -z "$PUBLIC_IP" ]; then
  echo "Error: Unable to detect the 192.168.4.x IP address."
  exit 1
fi


# ============================
# Generate kubeadm Join Config
# ============================
echo -e "${CYAN}Installing yq to configure  kubeadm join configuration file ...${NC}"
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq

# ============================
# Join the Cluster
# ============================
if [ -f "${KUBE_JOIN_FILE}" ]; then
  echo -e "${CYAN}Joining the Kubernetes cluster...${NC}"
  sudo yq eval ".nodeRegistration.kubeletExtraArgs[\"node-ip\"] = \"${PUBLIC_IP}\"" -i ${KUBE_JOIN_FILE}
  sudo kubeadm join --config="${KUBE_JOIN_FILE}"
else
  echo -e "${RED}Error: kubeadm join configuration file not found at ${KUBE_JOIN_FILE}.${NC}"
  exit 1
fi


# Restart and enable kubelet
echo "Restarting and enabling kubelet..."
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet

echo -e "${CYAN} verify kubelet config in :/var/lib/kubelet/config.yaml ...${NC}"
cat /var/lib/kubelet/config.yaml

echo -e "${GREEN}#### Worker node provisioning complete ####.${NC}"
echo ""
