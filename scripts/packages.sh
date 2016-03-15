#!/bin/bash

while [[ $# > 1 ]]
do
  key="$1"
  case $key in
    -s|--simulator)
      simulator="$2"
      shift
      ;;
    -a|--all_simulators)
      all_simulators="$2"
      shift
      ;;
    -i|--node_ip)
      coprhd_ip="$2"
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
  shift
done

# Report proxy settings
echo "Proxy settings are: "
echo `env | grep -i prox`

#remove if existing, otherwise python-devel and other install will raise a conflict
# zypper -n remove patterns-openSUSE-minimal_base-conflicts

#install required packages
zypper -n install wget telnet nano ant apache2-mod_perl createrepo expect gcc-c++ gpgme inst-source-utils java-1_8_0-openjdk java-1_8_0-openjdk-devel kernel-default-devel kernel-source kiwi-desc-isoboot kiwi-desc-oemboot kiwi-desc-vmxboot kiwi-templates libtool openssh-fips perl-Config-General perl-Tk python-libxml2 python-py python-requests setools-libs python-setools qemu regexp rpm-build sshpass sysstat unixODBC xfsprogs xml-commons-jaxp-1.3-apis zlib-devel git git-core glib2-devel libgcrypt-devel libgpg-error-devel libopenssl-devel libuuid-devel libxml2-devel pam-devel pcre-devel perl-Error python-devel readline-devel subversion xmlstarlet xz-devel libpcrecpp0 libpcreposix0 ca-certificates-cacert p7zip python-iniparse python-gpgme yum keepalived bridge-utils

# Grab the Simulators
# Grab the SMIS Simulator if enabled
SIMULATOR_VERSION="smis-simulators-1.0.0.0.1455598800.zip"
if [ "$simulator" = true ] || [ "$all_simulators" = true ]; then
  # Download to /vagrant directory if needed
  echo "Installing SMIS Simulator"
  if [ ! -e /vagrant/$SIMULATOR_VERSION ]; then
     wget "https://coprhd.atlassian.net/wiki/download/attachments/6652057/$SIMULATOR_VERSION?version=1&modificationDate=1455833007237&api=v2" -O "/vagrant/$SIMULATOR_VERSION"
  fi
  # Configure SMIS
  mkdir -p /opt/storageos
  unzip /vagrant/$SIMULATOR_VERSION -d /opt/storageos/
  # Enable version 4.6.2 SMI-S for Sanity Testing
  sed -i 's/^VERSION=80/#VERSION=80/' /opt/storageos/ecom/providers/OSLSProvider.conf
  sed -i 's/^#VERSION=462/VERSION=462/' /opt/storageos/ecom/providers/OSLSProvider.conf
  cd /opt/storageos/ecom/bin
  chmod +x  ECOM
  chmod +x  system/ECOM
  # Don't Start the simulator - let the run simulator.sh script do it.
fi  # SMIS_Simulator or ALL_Simulators

# Grab All Simulators and Install (SMIS already done above)
if [ "$all_simulators" = true ]; then
  echo "Installing Cisco, LDAP, Windows, and VPlex Simulators"
  # First Cisco Simulator
  mkdir /simulator
  wget 'https://coprhd.atlassian.net/wiki/download/attachments/6652057/cisco-sim.zip?version=4&modificationDate=1453406325249&api=v2' -O /simulator/cisco_sim.zip
  cd /simulator
  unzip cisco_sim.zip
  cd cisco-sim
  # Update Config files for correct directory
  cp bashrc ~/.bashrc
  sed -i 's/CISCO_SIM_HOME=\/cisco-sim/CISCO_SIM_HOME=\/simulator\/cisco-sim/' ~/.bashrc
  sed -i 's/chmod -R 777 \/cisco-sim/chmod -R 777 \/simulator\/cisco-sim/' ~/.bashrc
  source ~/.bashrc
  sed -i "s#args=('\/cisco-sim\/#args=('\/simulator\/cisco-sim\/#" /simulator/cisco-sim/config/logging.conf
  # Update sshd_config to allow root login - that's how Cisco Sim works
  sed -i "s/PermitRootLogin no/PermitRootLogin yes/" /etc/ssh/sshd_config
  service sshd restart

  # Second, LDAP Simulator
  wget 'https://coprhd.atlassian.net/wiki/download/attachments/6652057/ldapsvc-1.0.0.zip?version=2&modificationDate=1453406325338&api=v2' -O /simulator/ldap.zip
  cd /simulator
  unzip ldap.zip
  # Don't Start LDAP Simulator, let simulator.sh do that

  # Third, Windows Host Simulator
  wget 'https://coprhd.atlassian.net/wiki/download/attachments/6652057/win-sim.zip?version=3&modificationDate=1453406324934&api=v2' -O /simulator/win_host.zip
  cd /simulator
  unzip win_host.zip
  cd win-sim
  # Update Provider IP for SMIS Simulator address (running on CoprHD in this setup)
  sed -i "s/<provider ip=\"10.247.66.220\" username=\"admin\" password=\"#1Password\" port=\"5989\" type=\"VMAX\"><\/provider>/<provider ip=\"${coprhd_ip}\" username=\"admin\" password=\"#1Password\" port=\"5989\" type=\"VMAX\"><\/provider>/" /simulator/win-sim/config/simulator.xml
   echo "${coprhd_ip} winhost1 winhost2 winhost3 winhost4 winhost5 winhost6 winhost7 winhost8 winhost9 winhost10" >> /etc/hosts
   # Don't start the Windows Host Simulator, let simulator.sh do that

  # Fourth, VPLEX Simulator
  wget 'https://coprhd.atlassian.net/wiki/download/attachments/6652057/vplex-sim.zip?version=4&modificationDate=1453406325096&api=v2' -O /simulator/vplex.zip
  cd /simulator
  unzip vplex.zip
  cd vplex-simulators-1.0.0.0.41/
  # Edit IP Address for the SMIS provider and Vplex Simulator address (both CoprHD IP in this setup)
  sed -i "s/SMIProviderIP=10.247.98.128:5989,10.247.98.128:7009/SMIProviderIP=${coprhd_ip}:5989/" vplex_config.properties
  sed -i "s/#VplexSimulatorIP=10.247.98.128/VplexSimulatorIP=${coprhd_ip}/" vplex_config.properties
  #sed -i 's/RP_ENABLE=true/RP_ENABLE=false/' vplex_config.properties
  chmod +x ./run.sh
  # Don't start VPLEX Simulator, let simulator.sh do that
fi
