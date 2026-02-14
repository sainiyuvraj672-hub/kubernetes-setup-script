#!/bin/bash

# --- CONFIGURABLE VARIABLES ---
MASTER_IP="192.168.29.15"
NODE1_IP="192.168.29.20"
NODE2_IP="192.168.29.95"
MASTER_HOSTNAME="master.example.com"
NODE1_HOSTNAME="node1.example.com"
NODE2_HOSTNAME="node2.example.com"
POD_CIDR="10.244.0.0/16"
# ------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root"
    exit 1
fi

echo "[1/15] Disabling SELinux..."
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

echo "[2/15] Disabling swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "[3/15] Enabling IP forwarding..."
tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

echo "[4/15] Loading kernel modules..."
modprobe br_netfilter
tee /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
EOF

echo "[5/15] Disabling firewall..."
systemctl stop firewalld
systemctl disable firewalld

echo "[6/15] Updating /etc/hosts..."
cat <<EOF >> /etc/hosts
$MASTER_IP    master $MASTER_HOSTNAME
$NODE1_IP     node1  $NODE1_HOSTNAME
EOF

echo "[7/15] Setting hostname to $MASTER_HOSTNAME..."
hostnamectl set-hostname $MASTER_HOSTNAME

echo "[8/15] Installing Docker and containerd..."
yum remove -y docker* buildah
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io

echo "[9/15] Configuring containerd to use SystemdCgroup..."
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

echo "[10/15] Starting Docker..."
systemctl start docker
systemctl enable docker

echo "[11/15] Installing Kubernetes components..."
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

echo "[12/15] Initializing Kubernetes Master..."
kubeadm init --pod-network-cidr=$POD_CIDR --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

echo "[13/15] Configuring kubectl for root user..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "[14/15] Installing Calico CNI plugin..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

echo "[15/15] ✅ Kubernetes Master node setup complete!"

echo "Made by the Yuvraj Saini"