# Created by Jonas Rosland, @virtualswede & Matt Cowger, @mcowger
# Many thanks to this post by James Carr: http://blog.james-carr.org/2013/03/17/dynamic-vagrant-nodes/
# Extended by cebruns for CoprHD Simulator Setup

########################################################
#
# Settings for Simulator
#
########################################################
network = "192.168.100"
domain = 'sim.local'

script_proxy_args = ""
# Check if we are currently behind proxy
# We will pass into build/provision scripts if set
if ENV["http_proxy"] || ENV["https_proxy"]
  if !(Vagrant.has_plugin?("vagrant-proxyconf"))
    raise StandardError, "Env Proxy set but vagrant-proxyconf not installed. Fix with: vagrant plugin install vagrant-proxyconf"
   end
   # Remove http and https from proxy setting
   temp = ENV["http_proxy"].dup
   temp.slice! "http://"
   http_proxy, http_proxy_port = temp.split(":")
   script_proxy_args = " --proxy #{http_proxy} --port #{http_proxy_port}"

   # Some proxies use http or https as secure proxy, handle both
   temp = ENV["https_proxy"].dup
   temp =~ /https*:\/\/(.*)/
   https_proxy, https_proxy_port = $1.split(":")
   script_proxy_args += " --secure_proxy #{https_proxy} --secure_port #{https_proxy_port}"
   script_proxy_args += " --secure_proxy #{https_proxy} --secure_port #{https_proxy_port}"
end

########################################################
#
# Simulator VM Settings
#
########################################################
sim_node_ip = "#{network}.12"
sim_vagrantbox = "vchrisb/openSUSE-13.2_64"
sim_vagrantboxurl = "https://atlas.hashicorp.com/vchrisb/boxes/openSUSE-13.2_64/versions/0.1.3/providers/virtualbox.box"

# Simulated Backend - set to true to get VNX/VMAX Simulated Backends
smis_simulator = false

# All Simulators - set to true for Sanity Testing (will include smis_simulator)
all_simulators = true

########################################################
#
# Launch the VM and Provision
#
########################################################
Vagrant.configure("2") do |config|

  # If Proxy is set when provisioning, we set it permanently in each VM
  # If Proxy is not set when provisioning, we won't set it
  if Vagrant.has_plugin?("vagrant-proxyconf")
    if ENV["http_proxy"]
      config.proxy.http    = ENV["http_proxy"]
    end
    if ENV["https_proxy"]
      config.proxy.https   = ENV["https_proxy"]
    end
    if ENV["ftp_proxy"]
      config.proxy.ftp     = ENV["ftp_proxy"]
    end
    config.proxy.no_proxy = "#{sim_node_ip}"
    if ENV["no_proxy"]
      config.proxy.no_proxy += "," + ENV["no_proxy"]
    end
  end

  # Enable caching to speed up package installation for second run
  # vagrant plugin install vagrant-cachier
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

########################################################
#
# Launch Simulator
#
########################################################
  config.vm.define "simulator" do |simulator|
     simulator.vm.box = "#{sim_vagrantbox}"
     simulator.vm.box_url = "#{sim_vagrantboxurl}"
     simulator.vm.host_name = "simulator1"
     simulator.vm.network "private_network", ip: "#{sim_node_ip}"

     # configure virtualbox provider
     simulator.vm.provider "virtualbox" do |v|
         v.gui = false
         v.name = "Simulator"
         v.memory = 1024
         v.cpus = 1
     end

     # Setup Swap space
     simulator.vm.provision "shell" do |s|
      s.path = "scripts/swap.sh"
     end

     # Install pre-req packages and simulators
     simulator.vm.provision "shell" do |s|
      s.path = "scripts/packages.sh"
      s.args = "-s #{smis_simulator} -a #{all_simulators} --node_ip #{sim_node_ip}"
     end

      # Setup ntpdate crontab
      simulator.vm.provision "shell" do |s|
        s.path = "scripts/crontab.sh"
        s.privileged = false
      end

     # Launch Simulators - always runs
     simulator.vm.provision "shell", run: "always" do |s|
      s.path = "scripts/simulators.sh"
      s.args = "-s #{smis_simulator} -a #{all_simulators} --node_ip #{sim_node_ip}"
     end

     config.vm.provision "shell", inline: "service network restart", run: "always"

  end
end
