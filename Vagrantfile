# -*- mode: ruby -*-
# vi: set ft=ruby :
MEM_MASTER=2048
MEM_WORKER=3072
CPU_MASTER=2
CPU_WORKER=3


ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|

  config.vm.provision "shell", path: "bootstrap.sh"

  # Kubernetes Master Server
  config.vm.define "kmaster" do |kmaster|
    kmaster.vm.box = "bento/ubuntu-22.04"
    kmaster.vm.hostname = "kmaster.example.com"
    kmaster.vm.network "private_network", ip: "10.37.129.100"
    kmaster.vm.provider "parallels" do |v|
      v.memory = MEM_MASTER
      v.cpus = CPU_MASTER
    end
    kmaster.vm.provision "shell", path: "bootstrap_kmaster.sh"
  end

  NodeCount = 1

  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "kworker#{i}" do |workernode|
      workernode.vm.box =  "bento/ubuntu-22.04"
      workernode.vm.hostname = "kworker#{i}.example.com"
      workernode.vm.network "private_network", ip: "10.37.129.10#{i}"
      workernode.vm.provider "parallels" do |v|
        v.memory = MEM_WORKER 
        v.cpus = CPU_WORKER
      end
      workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
     end
  end
end
