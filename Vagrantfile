# -*- mode: ruby -*-
# vi: set ft=ruby :

#@todo - determine actual amount to expand hdd 


# Load overrides
require 'yaml'
settings_path = '.vagrant_settings'
settings = {}

if File.exist?(settings_path)
  settings = YAML.load_file(settings_path)
end

VAGRANT_CPUS         = settings["VAGRANT_CPUS"]         || 4
VAGRANT_MEMORY       = settings["VAGRANT_MEMORY"]       || 8192
VAGRANT_NETWORK_NAME = settings["VAGRANT_NETWORK_NAME"] || "vagrant-libvirt-test"
VAGRANT_NETWORK_ADDR = settings["VAGRANT_NETWORK_ADDR"] || "192.168.121.0/24"

# Vagrant
Vagrant.configure("2") do |config|
  config.vm.box = "rockylinux/9"
  config.vm.network "private_network", type: "dhcp"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Libvirt settings
  config.vm.provider :libvirt do |libvirt|
    libvirt.cpu_mode = "host-model"
    libvirt.cpus = VAGRANT_CPUS
    libvirt.machine_virtual_size = 50
    libvirt.memory = VAGRANT_MEMORY
    libvirt.management_network_name = VAGRANT_NETWORK_NAME
    libvirt.management_network_address = VAGRANT_NETWORK_ADDR
    libvirt.nested = true
  end

  config.vm.synced_folder ".", "/vagrant",type: "nfs",nfs_version: 4,nfs_udp: false
    
  
  # expand the larger hard drive - for me this is vda5 - use lsblk 
  config.vm.provision "shell", inline: <<-SHELL
      dnf install -y cloud-utils-growpart
      growpart /dev/vda 5
      xfs_growfs /dev/vda5
    SHELL

  config.vm.synced_folder "scratch", "/scratch", create: true

  # Provision with Ansible
  config.vm.provision "ansible" do |ansible|
    ENV['ANSIBLE_ROLES_PATH'] = File.dirname(__FILE__) + "/roles"
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "workstation.yml"
    ansible.raw_arguments = ["--diff"]
  end

end
