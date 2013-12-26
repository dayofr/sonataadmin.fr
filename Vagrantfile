# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos-6.4-x86_64"
  config.vm.box_url = "https://dl.dropboxusercontent.com/s/6hdm9hng4u5ohyq/centos-6.4-x86_64.box"

  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :forwarded_port, guest: 443, host: 8443
  
  config.vm.provider "virtualbox" do |v|
	v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  config.vm.network "private_network", ip: "10.11.12.13"
  config.vm.synced_folder ".", "/vagrant", nfs: true
  config.nfs.map_uid = Process.uid
  config.nfs.map_gid = Process.gid

  config.vm.provision "shell", path: "app/config/vagrant.sh"
end
