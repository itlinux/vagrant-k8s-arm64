#!/bin/bash

# Join worker nodes to the Kubernetes cluster
echo "[TASK 1] Join node to Kubernetes Cluster"

# Configure containerd cgroup driver
sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Wait for join script to exist
echo "Waiting for join script..."
until [ -f /vagrant/configs/joincluster.sh ]; do
  echo "  join script not ready, sleeping 5s..."
  sleep 5
done

# Join the cluster
sudo bash /vagrant/configs/joincluster.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to join cluster"
  exit 1
fi

echo "[TASK IMPORTANT!]"
echo "Wait a few minutes before running the kubectl below"
echo 'vagrant ssh kmaster -c "kubectl apply -f /home/vagrant/metal-lb.yml"'
echo "[TASKS COMPLETED]"
