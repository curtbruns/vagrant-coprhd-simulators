vagrant-coprhd-simulators
---------------
# Overview
This vagrant environment will download, provision, and launch the simulators that can be used with CoprHD for Sanity Testing.  This includes the LDAP Simulator, Cisco MDS Simulator, Windows Host Simulator, VPlex Simuator, and SMIS Storage Simulator.  

# Requirements
* vagrant
  * Nice-to-have: vagrant-cachier for caching packages - really speeds up subsequent installs
  * `vagrant plugin install vagrant-cachier`
* virtualbox

# Usage
* Modify the Vagrantfile for the Host-only network you want to create/use for Virtual Machine (VM)
* Launch/Provision the VM
  * `vagrant up`
* Note: The first time the VM is launched, all the packages will be downloaded, configured, and deployed.  Subsequent boots will only start the already-downloaded simulators and will be much faster.  If something goes wrong, you can easily wipe out the VM and start over with 'vagrant destroy' and then 'vagrant up'

# Access the VM
* `vagrant ssh`

# To run Sanity testing on CoprHD against this VM
* Modify the sanity.conf file in two areas:
1. HW_SIMULATOR_IP: Set this to the IP address of this VM, which is set in Vagrantfile
2. SIMULATOR_CISCO_MDS_PW: Set this to 'vagrant' as that is the root password for this VM
