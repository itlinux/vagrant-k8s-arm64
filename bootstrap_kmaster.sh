#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# TASK 1 — Configure containerd cgroup driver
# ─────────────────────────────────────────────
echo "[TASK 1] Configure containerd cgroup driver (systemd)"
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# ─────────────────────────────────────────────
# TASK 2 — Initialize Kubernetes Cluster
# ─────────────────────────────────────────────
echo "[TASK 2] Initialize Kubernetes Cluster"
echo "Waiting for 10.37.129.100 to be available..."
until ip a | grep -q "10.37.129.100"; do
  echo "  interface not ready, sleeping 5s..."
  sleep 5
done
echo "Interface is up."
sleep 10

sudo kubeadm init \
  --apiserver-advertise-address=10.37.129.100 \
  --apiserver-cert-extra-sans=10.37.129.100 \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket unix:///run/containerd/containerd.sock |
  tee /tmp/kubelog

if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "ERROR: kubeadm init failed. Check /tmp/kubelog"
  exit 1
fi

# ─────────────────────────────────────────────
# TASK 3 — Copy kubeconfig
# ─────────────────────────────────────────────
echo "[TASK 3] Copy kube admin config"
mkdir -p /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

# Write to /vagrant/configs so worker nodes can consume it
mkdir -p /vagrant/configs
sudo cp /etc/kubernetes/admin.conf /vagrant/configs/config
sudo chmod 644 /vagrant/configs/config

# ─────────────────────────────────────────────
# TASK 4 — Deploy Antrea CNI
# ─────────────────────────────────────────────
echo "[TASK 4] Deploy Antrea CNI"
echo "Waiting for API server to be ready..."
until sudo -u vagrant kubectl get nodes &>/dev/null; do
  sleep 5
done

sudo -u vagrant kubectl apply -f \
  https://raw.githubusercontent.com/antrea-io/antrea/main/build/yamls/antrea.yml

# ─────────────────────────────────────────────
# TASK 5 — Generate join command
# ─────────────────────────────────────────────
echo "[TASK 5] Generate and save cluster join command"
kubeadm token create --print-join-command >/vagrant/configs/joincluster.sh
chmod +x /vagrant/configs/joincluster.sh

# ─────────────────────────────────────────────
# TASK 6 — Shell enhancements for vagrant user
# ─────────────────────────────────────────────
echo "[TASK 6] Configure kubectl bash completion and alias"
sudo -i -u vagrant bash <<EOF
sudo apt -y install bash-completion 2>/dev/null || true
echo "source <(kubectl completion bash | sed s/kubectl/k/g)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
EOF

# ─────────────────────────────────────────────
# TASK 7 — Install Helm (direct binary, no apt repo)
# ─────────────────────────────────────────────
echo "[TASK 7] Installing Helm"
HELM_VER="v3.17.1"
ARCH=$(dpkg --print-architecture) # returns amd64 or arm64
curl -fsSL https://get.helm.sh/helm-${HELM_VER}-linux-${ARCH}.tar.gz -o /tmp/helm.tar.gz
tar -zxvf /tmp/helm.tar.gz -C /tmp
sudo mv /tmp/linux-${ARCH}/helm /usr/local/bin/helm
helm version

# ─────────────────────────────────────────────
# TASK 8 — Add Helm repos (Traefik + MetalLB)
# ─────────────────────────────────────────────
echo "[TASK 8] Adding Traefik and MetalLB Helm repos"
su - vagrant -c "helm repo add traefik https://traefik.github.io/charts"
su - vagrant -c "helm repo add metallb https://metallb.github.io/metallb"
su - vagrant -c "helm repo update"

# ─────────────────────────────────────────────
# TASK 9 — Create Traefik values file
# Note: 'traefikee' is Enterprise Edition — free chart is 'traefik/traefik'
# ─────────────────────────────────────────────
echo "[TASK 9] Creating Traefik values file"
su - vagrant -c "helm show values traefik/traefik > /home/vagrant/traefik-values.yml"

# ─────────────────────────────────────────────
# TASK 10 — Deploy MetalLB
# ─────────────────────────────────────────────
echo "[TASK 10] Deploy MetalLB"
su - vagrant -c "kubectl create ns metallb --dry-run=client -o yaml | kubectl apply -f -"

# Remove control-plane taint so pods can schedule on kmaster
su - vagrant -c "kubectl taint nodes kmaster node-role.kubernetes.io/control-plane:NoSchedule-"

# Pre-create memberlist secret
su - vagrant -c "kubectl create secret generic -n metallb metallb-memberlist \
  --from-literal=secretkey=\"\$(openssl rand -base64 128)\""

# Install without --wait so it doesn't block on worker node scheduling
su - vagrant -c "helm install metallb metallb/metallb -n metallb"

su - vagrant -c cat <<EOF >metal-lb.yml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb
spec:
  addresses:
  - 10.37.129.120-10.37.129.140
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2advertisement
  namespace: metallb
spec:
  ipAddressPools:
  - first-pool
EOF
chown vagrant:vagrant /home/vagrant/metal-lb.yml

echo "[DONE] kmaster provisioning complete"
