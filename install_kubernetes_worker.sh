#!/bin/bash

# This script installs a Kubernetes worker node and joins it to the cluster

# --- CHECK ROOT ---
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root"
    exit 1
fi

# --- 1. Disable SELinux ---
echo "Disabling SELinux..."
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# --- 2. Disable Swap ---
echo "Disabling swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

# --- 3. Enable IP Forwarding ---
echo "Configuring sysctl for Kubernetes networking..."
tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# --- 4. Load Kernel Modules ---
echo "Loading kernel modules..."
modprobe br_netfilter
tee /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF

# --- 5. Disable Firewall (for lab/demo) ---
echo "Disabling firewalld..."
systemctl stop firewalld
systemctl disable firewalld

# --- 6. Install Docker + containerd ---
echo "Installing Docker and containerd..."
yum remove -y docker* buildah
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io

# --- 7. Configure containerd to use systemd ---
echo "Configuring containerd..."
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

# --- 8. Start Docker ---
echo "Starting Docker..."
systemctl start docker
systemctl enable docker

# --- 9. Install Kubernetes Components ---
echo "Installing kubeadm, kubelet, kubectl..."
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
systemctl start kubelet

# --- 10. Join the Cluster ---
if [[ -z "$1" ]]; then
    echo "❌ Please provide the kubeadm join command."
    echo "Usage: sudo ./install_kubernetes_worker.sh \"<kubeadm join ...>\""
    exit 1
else
    echo "Joining the Kubernetes cluster..."
    eval "$1"
    echo "✅ Worker node has successfully joined the cluster!"
fi

echo "This script is made by Yuvraj saini"