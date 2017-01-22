# -*- mode: ruby -*-
# vi: set ft=ruby :

# dictionary containing the various groups mapped to the locally running
# development environment
$development_groups = {
  "development_hosts" => [
    "nms.dev",
    "bokkusu.dev",
  ],
  "management_servers" => [
    "nms.dev",
  ],
  "ix_servers" => [
    "bokkusu.dev",
  ],
}

# Script to run to prepare a plain box to run ansible
$pre_provision_script = <<END_SCRIPT

# Make sure system has a FQDN
grep -q '\.dev$' /etc/hostname
if [[ ${?} -eq 1 ]]; then
  echo '[+] Converting hostname to fqdn'
  sed -i -e 's,$,\.dev,g' /etc/hostname
  hostname `cat /etc/hostname`
fi

# Bind the fqdn to the host-only network ip address
grep -q '127.0.1.1' /etc/hosts
if [[ ${?} -eq 0 ]]; then
  echo '[+] Binding fqdn to host-only ip address'
  cat /etc/hosts | grep -v '127.0.1.1' > /etc/hosts.new
  IP=`ip -4 addr show dev eth1 | grep global | awk '{print $2}' | cut -d/ -f1`
  echo -e "\n${IP} `hostname -f` `hostname -s`" >> /etc/hosts.new
  mv /etc/hosts.new /etc/hosts
fi

# Link various ansible directories into place
BASEDIR='/etc/ansible'
[[ -d "${BASEDIR}" ]] || mkdir -p "${BASEDIR}"
[[ -L "${BASEDIR}/host_vars" ]] \
  || ln -s /vagrant/host_vars "${BASEDIR}/host_vars"
[[ -L "${BASEDIR}/group_vars" ]] \
  || ln -s /vagrant/group_vars "${BASEDIR}/group_vars"
[[ -L "${BASEDIR}/roles" ]] || ln -s /vagrant/roles "${BASEDIR}/roles"

END_SCRIPT

# Main configuration of vagrant starts here
Vagrant.configure(2) do |config|
  # Use debian/jessie 64-bit as a default
  config.vm.box = "debian/jessie64"

  # Workaround for nic: stdin: is not a tty
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  # Allocate 1GB ram and 2 cores to each VM by default
  config.vm.provider "virtualbox" do |machine_defaults|
    machine_defaults.cpus = 2
    machine_defaults.memory = "1024"
  end

  # Run a simple shell-based provisioner to prepare a vm to be provisioned
  config.vm.provision "shell", inline: $pre_provision_script

  # Run ansible on the host to perform provisioning
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "site.yml"
    ansible.sudo = true
    ansible.groups = $development_groups
  end

  # Below are the various definitions for server roles within HKJL-NET. They
  # are configured on the .dev domain, using pre-configured ip addresses.

  # nms.dev -- Network Management Station. This system holds the PKI, IPAM and
  #            various other network related functionality.
  config.vm.define "nms.dev" do |nms|
    nms.vm.hostname = "nms.dev"
    nms.vm.network "private_network", ip: "10.0.3.10"

    # Allocate a bit more memory then the default in anticipation of the
    # running services.
    config.vm.provider "virtualbox" do |machine|
      machine.memory = "1536"
    end
  end

  # ix0*.dev -- An instance of an IX core node. This system runs openvpn which
  #             is connected to a bridge, which in turn is connected to other
  #             IX core nodes on the network. Spanning tree must be enabled to
  #             prevent the network from forming layer 2 loops.
  config.vm.define "bokkusu.dev" do |bokkusu|
    bokkusu.vm.hostname = "bokkusu.dev"
    bokkusu.vm.network "private_network", ip: "10.0.3.11"
  end
end
