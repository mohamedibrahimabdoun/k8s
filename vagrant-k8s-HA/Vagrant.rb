# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/xenial64"
  config.vm.provider :virtualbox do |vb|
   # vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--cpus", "1"]
  end  
   config.vm.define "k8s-master01" do |kube|
   kube.vm.network "private_network", ip: "10.10.1.11"
   kube.vm.network "public_network", bridge: "Wi-Fi:Intel(R) Dual Band Wireless-AC 7260" , ip: "192.168.1.121" 
   #config.vm.provision "shell"
   
    kube.vm.provision "shell" do |s|  
	 #s.run = "always"
	 s.inline= "sudo su"
	 s.inline= "sudo echo -e 'password\npassword'  | sudo passwd root"
	 #s.inline = "echo 'nameserver 192.168.1.1' >> /etc/resolv.conf"
	 #s.inline= "route add default gw 192.168.1.1"
	end
  end
  
  config.vm.define "k8s-master02" do |kube|
   kube.vm.network "private_network", ip: "10.10.1.12"
   kube.vm.network "public_network", bridge: "Wi-Fi:Intel(R) Dual Band Wireless-AC 7260" , ip: "192.168.1.122" 
   #config.vm.provision "shell"
   
    kube.vm.provision "shell" do |s|  
	 #s.run = "always"
	 s.inline= "sudo su"
	 s.inline= "sudo echo -e 'password\npassword'  | sudo passwd root"
	 #s.inline = "echo 'nameserver 192.168.1.1' >> /etc/resolv.conf"
	 #s.inline= "route add default gw 192.168.1.1"
	end
  end
  
    config.vm.define "k8s-master03" do |kube|
   kube.vm.network "private_network", ip: "10.10.1.13"
   kube.vm.network "public_network", bridge: "Wi-Fi:Intel(R) Dual Band Wireless-AC 7260" , ip: "192.168.1.123" 
   #config.vm.provision "shell"
   
    kube.vm.provision "shell" do |s|  
	 #s.run = "always"
	 s.inline= "sudo su"
	 s.inline= "sudo echo -e 'password\npassword'  | sudo passwd root"
	 #s.inline = "echo 'nameserver 192.168.1.1' >> /etc/resolv.conf"
	 #s.inline= "route add default gw 192.168.1.1"
	end
  end
  
#$script = << -SCRIPT
#echo I am provisioning...
#
##echo "r00tme" | passwd  root
##sudo cp /vagrant/hosts /etc/hosts
##curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
##sudo cp /vagrant/kubernetes.list /etc/apt/sources.list.d/kubernetes.list
#sudo apt-get update 
#sudo apt-get install -y docker.io kubelet kubeadm kubectl kubernetes-cni
##sudo rm -rf /var/lib/kubelet/*
##echo I am turning off swap...
##sudo swapoff -a
##echo I am joining NFS...
##sudo apt-get install nfs-common -y
#SCRIPT 

end
