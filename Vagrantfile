# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|

  config.vm.provision "shell", path: "bootstrap.sh"
  config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"

  # Kubernetes Master Server
  config.vm.define "kmaster" do |kmaster|
    kmaster.vm.box = "bento/ubuntu-22.04"
    kmaster.vm.hostname = "kmaster.example.com"
    kmaster.vm.network "private_network", ip: "10.37.129.100"
    kmaster.vm.provider "parallels" do |v|
    #kmaster.vm.provider "vmware_desktop" do |v|
      #v.name = "kmaster"
      v.memory = 2048
      v.cpus = 2
      #v.gui = true
      #v.vmx["virtualhw.version"] = 18
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
      #workernode.vm.provider "vmware_desktop" do |v|
        #v.name = "kworker#{i}"
        v.memory = 3072
        v.cpus = 3
      #  v.gui = true
      #  v.vmx["virtualhw.version"] = 18
      end
      workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
      config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/authorized_keys"

    end
  end

end
