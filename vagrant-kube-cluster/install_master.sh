#!/bin/bash

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


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
NAMESPACE_MONITORING="monitoring"
NAMESPACE_ISTIO="istio-system"
METALLB_NAMESPACE="metallb-system"

echo -e "${YELLOW}..#### Provisioning a Worker Node ####..${NC}"

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
echo -e "${CYAN}Setting up SSH for root user....${NC}"
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
echo -e "${CYAN}Updating SSHD configuration....${NC}"
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 5. Set root password
echo "Setting root password..."
echo -e "r00tr00t\nr00tr00t" | sudo passwd root

# 6. Copy hosts file
echo -e "${CYAN}Copying hosts file....${NC}"
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
    net-tools

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
echo -e "${CYAN}Adding Kubernetes APT repository for verion ${KUBE_VERSION}...${NC}"
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

# Hold the Kubernetes packages at the current version
sudo apt-mark hold kubelet kubeadm kubectl

# Detect the 192.168.4.x IP
echo -e "${CYAN} Detect the 192.168.4.x IP ${NC}"
PUBLIC_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.168\.4\.' | head -n 1)

if [ -z "$PUBLIC_IP" ]; then
  echo "Error: Unable to detect the 192.168.4.x IP address."
  exit 1
fi

echo -e "${CYAN} nodeIP: ${PUBLIC_IP}...${NC}"
# ============================
# Configure Kubelet
# ============================
echo -e "${CYAN}Configuring kubelet..${NC}"
sudo bash -c "cat <<EOF > /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
containerRuntime: remote
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
podInfraContainerImage: registry.k8s.io/pause:3.9
nodeIP: $PUBLIC_IP
EOF"

# ============================
# Restart and Enable kubelet
# ============================
echo -e "${CYAN}Restarting and enabling kubelet..${NC}"
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet

# ============================
# Verify Container Runtime
# ============================
echo -e "${CYAN}Verifying container runtime..${NC}"
crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock info

# ============================
# Initialize Kubernetes Cluster
# ============================
echo -e "${CYAN}Initializing Kubernetes cluster..${NC}"
# Reset any previous kubeadm state
sudo kubeadm reset -f || true

# Pull Kubernetes images to ensure consistency
echo -e "${CYAN}Pulling Kubernetes images..${NC}"
sudo kubeadm config images pull --kubernetes-version=${KUBE_VERSION}

# Initialize the cluster
echo -e "${CYAN}Initialize the cluster using kubeadm..${NC}"
sudo kubeadm init --kubernetes-version=${KUBE_VERSION} \
    --pod-network-cidr=${POD_NETWORK_CIDR} \
    --apiserver-cert-extra-sans=${APISERVER_ADVERTISE_ADDRESS} \
    --apiserver-advertise-address=${APISERVER_ADVERTISE_ADDRESS} \
    --ignore-preflight-errors=NumCPU

#    --apiserver-advertise-address=${APISERVER_ADVERTISE_ADDRESS} \
# ============================
# Set Up Local kubeconfig
# ============================
echo -e "${CYAN}Setting up local kubeconfig..${NC}"
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config



# ============================
# Install Helm
# ============================
echo -e "${CYAN}Installing Helm..${NC}"
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# ============================
# Install Cilium Using Helm
# ============================
echo -e "${CYAN}Installing Cilium pod network using Helm..${NC}"
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --version 1.14.2 \
  --namespace kube-system \
  --set kubeProxyReplacement=strict \
  --set k8sServiceHost=${APISERVER_ADVERTISE_ADDRESS} \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set podCIDR=${POD_NETWORK_CIDR} \
  --set tunnel=geneve \
  --set bpf.masquerade=true \
  --set ipv4.enabled=true \
  --set ipv6.enabled=false \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

echo "Your Kubernetes cluster should now be up and running."

########################################
# Install MetalLB
########################################
echo -e "${CYAN}Installing MetalLB...${NC}"
helm repo add metallb https://metallb.github.io/metallb && echo -e "${GREEN}MetalLB repo added.${NC}"
helm repo update && echo -e "${GREEN}Helm repos updated.${NC}"

helm install metallb metallb/metallb -n "$METALLB_NAMESPACE" --create-namespace \
  --set controller.tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set controller.tolerations[0].operator=Exists \
  --set controller.tolerations[0].effect=NoSchedule \
  --set speaker.tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set speaker.tolerations[0].operator=Exists \
  --set speaker.tolerations[0].effect=NoSchedule

echo -e "${YELLOW}Waiting for MetalLB controller to be ready...${NC}"
kubectl rollout status -n "$METALLB_NAMESPACE" deployment/metallb-controller
echo -e "${GREEN}MetalLB installed successfully.${NC}"

echo -e "${CYAN}Configuring MetalLB IPAddressPool...${NC}"
echo -e "${GREEN}Using IP range 192.168.4.200-192.168.4.220 for MetalLB...${NC}"

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.4.200-192.168.4.220
EOF

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
echo -e "${GREEN}MetalLB IPAddressPool and L2Advertisement configured.${NC}"

########################################
# Install Prometheus
########################################
echo -e "${CYAN}Installing Prometheus...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && echo -e "${GREEN}Prometheus repo added.${NC}"
helm repo update && echo -e "${GREEN}Helm repos updated.${NC}"
helm install prometheus prometheus-community/prometheus \
  --namespace "$NAMESPACE_MONITORING" \
  --create-namespace \
  --set server.tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set server.tolerations[0].operator=Exists \
  --set server.tolerations[0].effect=NoSchedule \
  --set server.persistentVolume.enabled=false \
  --set alertmanager.enabled=false \
  --set alertmanager.tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set alertmanager.tolerations[0].operator=Exists \
  --set alertmanager.tolerations[0].effect=NoSchedule \
  --set alertmanager.config.enabled=false \
  --set kube-state-metrics.enabled=true \
  --set kube-state-metrics.tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set kube-state-metrics.tolerations[0].operator=Exists \
  --set kube-state-metrics.tolerations[0].effect=NoSchedule \
  --set prometheus-pushgateway.enabled=false


echo -e "${YELLOW}Waiting for Prometheus pods to be ready...${NC}"
kubectl rollout status -n "$NAMESPACE_MONITORING" deployment/prometheus-server
echo -e "${GREEN}Prometheus installed successfully.${NC}"


########################################
# Install Grafana
########################################
echo -e "${CYAN}Installing Grafana...${NC}"
helm repo add grafana https://grafana.github.io/helm-charts && echo -e "${GREEN}Grafana repo added.${NC}"
helm repo update && echo -e "${GREEN}Helm repos updated.${NC}"
helm install grafana grafana/grafana \
  --namespace "$NAMESPACE_MONITORING" \
  --set tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set tolerations[0].operator=Exists \
  --set tolerations[0].effect=NoSchedule

echo -e "${YELLOW}Waiting for Grafana pod to be ready...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana -n "$NAMESPACE_MONITORING" --timeout=180s
echo -e "${GREEN}Grafana installed successfully.${NC}"

GRAFANA_PW=$(kubectl get secret --namespace "$NAMESPACE_MONITORING" grafana  -o jsonpath="{.data.admin-password}" | base64 --decode)
echo -e "${GREEN}Grafana admin password: $GRAFANA_PW${NC}"


# ============================
# Final Instructions
# ============================
echo "Kubernetes cluster initialized successfully!"

echo "To start using your cluster, ensure the kubeconfig is correctly set up:"
echo "mkdir -p ~/.kube"
echo "sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config"
echo "sudo chown $(id -u):$(id -g) ~/.kube/config"

echo "Installing Helm has been completed."

echo "Install a pod network, such as Cilium (already installed):"
echo "helm repo add cilium https://helm.cilium.io/"
echo "helm repo update"
echo "helm install cilium cilium/cilium --version 1.14.2 --namespace kube-system [additional parameters as needed]"

# Save the kubeadm join command to a shared file for workers
echo -e "${CYAN}Saving kubeadm join command.${NC}"
JOIN_COMMAND=$(sudo kubeadm token create --print-join-command --ttl 0)
echo "$JOIN_COMMAND" > /vagrant/join_command.sh
chmod +x /vagrant/join_command.sh

echo -e "${GREEN}#### Master node provisioning complete ####.${NC}"


# ============================
# Optional: Enable Firewall with Necessary Ports
# ============================
# Uncomment and configure the following lines to enable the firewall with necessary Kubernetes ports.
# WARNING: Disabling firewall can expose your system. Use with caution.

# echo "Configuring firewall rules..."
# sudo ufw allow 6443/tcp
# sudo ufw allow 2379:2380/tcp
# sudo ufw allow 10250:10252/tcp
# sudo ufw allow 30000:32767/tcp
# sudo ufw enable
