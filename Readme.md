# 🚀 Kubernetes Cluster Setup Using Bash Automation

> Build a Kubernetes cluster like a grown engineer — not by clicking, but by scripting.  
> One master. Multiple workers. Clean automation. Calm nerves.

This repository contains **Bash scripts** to install and configure a **Kubernetes cluster from scratch** on **CentOS / RHEL-based Linux systems** using:

- kubeadm
- containerd
- Calico CNI

The setup is ideal for **learning, labs, testing, and interview-ready demos**.

---

## 📂 Repository Structure

.
├── install_kubernetes_master.sh

├── install_kubernetes_worker.sh

└── README.md

---

## 🧱 Cluster Architecture

Master Node
- kube-apiserver
- kube-controller-manager
- kube-scheduler
- etcd

Worker Nodes
- kubelet
- kube-proxy
- containerd

Networking
- Calico CNI

---

## ⚙️ System Requirements

- Operating System: CentOS / Rocky Linux / AlmaLinux (7, 8, or 9)
- User: root
- Minimum 2 CPU cores
- Minimum 2 GB RAM
- All nodes must reach each other via IP
- Swap must be disabled

---

## 🔧 Configuration Variables

Edit inside both scripts:

MASTER_IP="192.168.29.15"
NODE1_IP="192.168.29.20"
NODE2_IP="192.168.29.95"

MASTER_HOSTNAME="master.example.com"
NODE1_HOSTNAME="node1.example.com"
NODE2_HOSTNAME="node2.example.com"

POD_CIDR="10.244.0.0/16"

---

## 🛠️ Master Node Installation

chmod +x install_kubernetes_master.sh
./install_kubernetes_master.sh

---

## 🧑‍🏭 Worker Node Installation

chmod +x install_kubernetes_worker.sh
./install_kubernetes_worker.sh

---

## 🔗 Join Worker Nodes

kubeadm token create --print-join-command

---

## ✅ Verify Cluster

kubectl get nodes

---

## 🌐 Networking

- CNI: Calico
- Pod CIDR: 10.244.0.0/16
- Runtime: containerd
- Cgroup: systemd

---

## 🏁 Final Thought

This setup teaches real Kubernetes.

## 📌 Author

**Yuvraj**
**Made in feb 2025**
