#!/bin/sh

# Install prerequisites
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg vim bash-completion binutils

# Setup terminal
echo 'colorscheme ron' >> ~/.vimrc
echo 'set tabstop=2' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
sed -i '1s/^/force_color_prompt=yes\n/' ~/.bashrc

# Remove old Kubernetes and Docker versions
apt-get remove -y docker.io kubelet kubeadm kubectl kubernetes-cni
apt-get autoremove -y

# Add Kubernetes repository
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Install Containerd
apt-get update
apt-get install -y containerd

# Configure Containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart Containerd
systemctl restart containerd
systemctl enable containerd

# Verify Containerd
containerd --version

# Install Kubernetes components
KUBE_VERSION=1.29.4
apt-get install -y kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
apt-mark hold kubelet kubeadm kubectl

# Configure kubelet to use Containerd
cat <<EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF

# Restart kubelet to pick up changes
systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet

# Initialize Kubernetes cluster
rm -rf /root/.kube/config
kubeadm reset -f
kubeadm init --kubernetes-version=${KUBE_VERSION} \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.4.100 \
  --ignore-preflight-errors=NumCPU

# Configure kubectl for root
mkdir -p ~/.kube
cp -i /etc/kubernetes/admin.conf ~/.kube/config

# Install Cilium CNI with adjusted Pod CIDR
kubectl create namespace kube-system
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --version 1.14.2 \
  --namespace kube-system \
  --set kubeProxyReplacement=strict \
  --set k8sServiceHost=192.168.4.100 \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set podCIDR=10.244.0.0/16 \
  --set tunnel=geneve \
  --set bpf.masquerade=true \
  --set ipv4.enabled=true \
  --set ipv6.enabled=false \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Configure kubectl for Vagrant user
echo "### Setting kubeconfig for the Vagrant user ###"
sudo mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube/config

# Verify the cluster
kubectl get nodes -o wide
kubectl get pods -A -o wide

# Print the command to join worker nodes
echo
echo "### COMMAND TO ADD A WORKER NODE ###"
kubeadm token create --print-join-command --ttl 0
