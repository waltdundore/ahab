# -*- mode: ruby -*-
# vi: set ft=ruby :

# ==============================================================================
# Single VM Vagrant Configuration
# ==============================================================================
# Creates a single VM for local testing
#
# To modify VM settings, edit config.yml:
#   - Playbook: config.yml (ansible.playbook)
#   - VM box: config.yml (vagrant.box)
#   - CPU count: config.yml (vagrant.cpus)
#   - Memory: config.yml (vagrant.memory)
#   - Network: config.yml (libvirt.network_name, libvirt.network_addr)
#   - Disk size: config.yml (libvirt.disk_size)

require_relative 'vagrant_common'

cfg = load_config
vagrant_cfg = cfg['vagrant'] || {}
libvirt_cfg = cfg['libvirt'] || {}
ansible_cfg = cfg['ansible'] || {}

# CONFIGURE: config.yml (ansible.playbook)
PLAYBOOK     = ansible_cfg['playbook'] || 'docker'
# CONFIGURE: config.yml (vagrant.box)
BOX          = vagrant_cfg['box'] || 'bento/fedora-43'
# CONFIGURE: config.yml (vagrant.cpus)
CPUS         = vagrant_cfg['cpus'] || 4
# CONFIGURE: config.yml (vagrant.memory)
MEMORY       = vagrant_cfg['memory'] || 16384
# CONFIGURE: config.yml (libvirt.network_name)
NETWORK_NAME = libvirt_cfg['network_name'] || 'vagrant-libvirt-test'
# CONFIGURE: config.yml (libvirt.network_addr)
NETWORK_ADDR = libvirt_cfg['network_addr'] || '192.168.121.0/24'
# CONFIGURE: config.yml (libvirt.disk_size)
DISK_SIZE    = libvirt_cfg['disk_size'] || 50

Vagrant.configure("2") do |config|
  config.vm.box = BOX
  config.vm.network "private_network", type: "dhcp"
  config.ssh.forward_agent = true
  config.vm.synced_folder "scratch", "/scratch", type: "rsync", create: true

  config.vm.provider :libvirt do |libvirt|
    libvirt.management_network_name = NETWORK_NAME
    libvirt.management_network_address = NETWORK_ADDR
  end

  config.vm.provider :parallels do |prl|
    prl.customize ['set', :id, '--device-bootorder', 'hdd0']
  end

  configure_providers(config.vm, CPUS, MEMORY, DISK_SIZE)
  configure_ansible(config.vm, PLAYBOOK)
end
