# -*- mode: ruby -*-
# vi: set ft=ruby :
# ==============================================================================
# Ahab Workstation Vagrantfile
# ==============================================================================
# Single source of truth: ../ahab.conf
# Purpose: Create workstation for deploying modules via docker-compose
# ==============================================================================

def read_config
  config_file = File.expand_path('../ahab.conf', __dir__)
  config = {}
  return config unless File.exist?(config_file)
  
  File.readlines(config_file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')
    
    key, value = line.split('=', 2)
    next unless key && value
    
    value = value.split('#')[0]
    next unless value
    
    value = value.strip
    next if value.empty?
    
    config[key.strip] = value
  end
  
  config
end

CONFIG = read_config

# Determine which OS to use
def get_box_name(config)
  os = config['DEFAULT_OS'] || 'fedora'
  
  case os.downcase
  when 'fedora'
    version = config['FEDORA_VERSION'] || '43'
    "bento/fedora-#{version}"
  when 'debian'
    version = config['DEBIAN_VERSION'] || '13'
    "bento/debian-#{version}"
  when 'ubuntu'
    version = config['UBUNTU_VERSION'] || '24.04'
    "bento/ubuntu-#{version}"
  else
    puts "WARNING: Unknown OS '#{os}', defaulting to Fedora 43"
    "bento/fedora-43"
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = get_box_name(CONFIG)
  config.vm.hostname = "ahab-workstation"
  config.vm.network "private_network", type: "dhcp"
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Sync ansible-control directory for module deployment
  config.vm.synced_folder ".", "/home/vagrant/ahab", type: "rsync",
    rsync__exclude: [".git/", ".vagrant/"],
    rsync__args: ["--verbose", "--archive", "--delete", "-z", "--copy-links"]
  
  config.vm.provider "parallels" do |prl|
    prl.name = "ahab-workstation"
    prl.memory = CONFIG['WORKSTATION_MEMORY'] || '4096'
    prl.cpus = CONFIG['WORKSTATION_CPUS'] || '2'
    prl.customize ["set", :id, "--nested-virt", "on"]
  end
  
  config.vm.provider "virtualbox" do |vb|
    vb.name = "ahab-workstation"
    vb.memory = CONFIG['WORKSTATION_MEMORY'] || '4096'
    vb.cpus = CONFIG['WORKSTATION_CPUS'] || '2'
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
  end
  
  # Provision with Ansible (following Ahab policy: no scripting in Vagrantfile)
  config.vm.provision "ansible_local" do |ansible|
    ansible.provisioning_path = "/home/vagrant/ahab"
    ansible.playbook = "playbooks/provision-workstation.yml"
    ansible.verbose = false
    ansible.install = true
    ansible.install_mode = "pip3"
    ansible.pip_install_cmd = "curl https://bootstrap.pypa.io/get-pip.py | sudo python3"
  end
end
