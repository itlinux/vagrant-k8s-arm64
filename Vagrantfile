# -*- mode: ruby -*-
# vi: set ft=ruby :
MEM_MASTER=12196
MEM_WORKER=6096
CPU_MASTER=4
CPU_WORKER=4
OS="bento/ubuntu-22.04"

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|

  config.vm.provision "shell", path: "bootstrap.sh"

  # Kubernetes Master Server
  config.vm.define "kmaster" do |kmaster|
    kmaster.vm.box = OS
    kmaster.vm.hostname = "kmaster.example.com"
    kmaster.vm.network "private_network", ip: "10.37.129.100"
    kmaster.vm.provider "parallels" do |v|
      v.memory = MEM_MASTER
      v.cpus = CPU_MASTER
    end
    kmaster.vm.provision "shell", path: "bootstrap_kmaster.sh"
  end

  NodeCount = 2

  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "kworker#{i}" do |workernode|
      workernode.vm.box =  OS
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
