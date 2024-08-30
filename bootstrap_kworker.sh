#!/bin/bash

# Join worker nodes to the Kubernetes cluster
echo "[TASK 1] Join node to Kubernetes Cluster"
apt  install -y sshpass >/dev/null 2>&1
#sshpass -p "kubeadmin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster.example.com:/joincluster.sh /joincluster.sh 2>/dev/null
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl daemon-reload
sudo systemctl restart kubelet

sshpass -p "kubeadmin" scp -o StrictHostKeyChecking=no kmaster.example.com:/tmp/joincluster.sh /joincluster.sh
sudo bash /joincluster.sh >/dev/null 2>&1
