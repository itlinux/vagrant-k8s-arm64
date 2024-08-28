#!/bin/bash

# change systemd to cfgroups
# Copy Kube admin config
echo "[TASK 1] change cgroupfs"
echo "\"Environment=\"KUBELET_CGROUP_ARGS=--cgroup-driver=cgroupfs\" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
#sudo sed -i 's/systemd/cgroupfs/' /var/lib/kubelet/config.yaml
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Initialize Kubernetes
echo "[TASK 2] Initialize Kubernetes Cluster"
sed -i 's#Environment="KUBELET_KUBECONFIG_ARGS=-.*#Environment="KUBELET_KUBECONFIG_ARGS=--kubeconfig=/etc/kubernetes/kubelet.conf --require-kubeconfig=true --cgroup-driver=systemd"#g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
kubeadm init --apiserver-advertise-address=10.37.129.100  --pod-network-cidr=192.168.0.0/16 |tee /tmp/kubelog 
#kubeadm init --apiserver-advertise-address=10.37.129.100 --bind-address=10.37.129.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null


# Copy Kube admin config
echo "[TASK 3] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

# Deploy flannel network
#echo "[TASK 4] Deploy Calico network"
#su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml"


# Generate Cluster join command
echo "[TASK 5] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /tmp/joincluster.sh


sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown vagrant.vagrant /home/vagrant/.kube/config
sudo apt -y install bash-completion
echo "source <(kubectl completion bash |sed s/kubectl/k/g)" >>.bashrc
echo "alias k=kubectl" >>.bashrc
EOF
# Deploying Antrea
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/antrea-io/antrea/main/build/yamls/antrea.yml"

# copy the config to local
#echo "[TASK 6] Downloading the kube config"
#vagrant ssh -c 'cat /etc/kubernetes/admin.conf' > .kube/config
