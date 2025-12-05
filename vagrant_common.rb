# ==============================================================================
# Shared Vagrant Configuration Functions
# ==============================================================================
# Reusable functions for Vagrantfile and Vagrantfile.multi
#
# Functions:
#   - load_config: Loads config.yml
#   - configure_providers: Sets CPU/memory for libvirt and Parallels
#   - configure_ansible: Configures Ansible provisioner

require 'yaml'

# Load configuration from config.yml
# CONFIGURE: config.yml (all settings)
def load_config
  config_file = File.join(File.dirname(__FILE__), 'config.yml')
  if File.exist?(config_file)
    YAML.load_file(config_file)
  else
    {}
  end
end

# Configure VM providers with consistent CPU and memory settings
# Parameters passed from Vagrantfile (loaded from config.yml)
def configure_providers(vm, cpus, memory, disk_size = nil)
  vm.provider :libvirt do |libvirt|
    libvirt.cpu_mode = "host-model"
    libvirt.cpus = cpus
    libvirt.memory = memory
    libvirt.nested = true
    libvirt.machine_virtual_size = disk_size if disk_size
  end

  vm.provider :parallels do |prl|
    prl.cpus = cpus
    prl.memory = memory
    prl.update_guest_tools = true
  end
end

# Configure Ansible provisioner
# CONFIGURE: config.yml (ansible.playbook)
def configure_ansible(vm, playbook)
  vm.provision "ansible" do |ansible|
    ENV['ANSIBLE_ROLES_PATH'] = File.dirname(__FILE__) + "/roles"
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "playbooks/#{playbook}.yml"
    ansible.raw_arguments = ["--diff"]
  end
end
