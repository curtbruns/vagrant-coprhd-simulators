#!/bin/bash
#################################################
# Install Simulators
#################################################
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
      simulator_ip="$2"
      shift
      ;;
    *)
      # unknown option
      ;;
  esac
  shift
done

# Grab the SMIS Simulator if enabled
if [ "$simulator" = true ] || [ "$all_simulators" = true ]; then
  cd /opt/storageos/ecom/bin
  ./ECOM &
  INTERVAL=5
  TIMER=1
  COUNT=0
  echo "Checking for ECOM Service Starting...."
  while [ $COUNT -lt 4 ];
  do
    COUNT="$(netstat -anp  | grep -c ECOM)"
    printf "."
    sleep $INTERVAL
    let TIMER=TIMER+$INTERVAL
    if [ $TIMER -gt 30 ]; then
      echo "SMIS Simulator did not start!" >&2
      exit 1
    fi
  done
fi  # SMIS_Simulator
echo "SMIS Simulator Started!"

# Grab All Simulators and Install (SMIS already done above)
if [ "$all_simulators" = true ]; then
  # Cisco Simulator does not need an active service - it is part of .bashrc and
  # CoprHD will ssh into this host to access Cisco Simulator Commands
  echo "Cisco Simulator is Running"

  # Second, LDAP Simulator
  echo "Starting LDAP Simulator Service"
  cd /simulator/ldapsvc-1.0.0/bin
  ./ldapsvc &
  sleep 10 
  curl -X POST -H "Content-Type: application/json" -d "{\"listener_name\": \"COPRHDLDAPSanity\"}" http://${simulator_ip}:8082/ldap-service/start

  # Third, Windows Host Simulator
  echo "Starting Windows Host Simulator Service"
  cd /simulator/win-sim
  ./runWS.sh &
  sleep 5

  # Fourth, VPLEX Simulator
  echo "Starting VPlex Simulator Service"
  cd /simulator/vplex-simulators-1.0.0.0.41/
  ./run.sh &
  # Need to wait for service to be running
  sleep 2
  PID=`ps -ef | grep [v]plex_config | awk '{print $2}'`
  if [[ -z ${PID} ]]; then
     echo "Vplex_Config Simulator Not running - Fail"
     exit 1
  fi
  TIMER=1
  INTERVAL=3
  echo "Waiting for VPlex Simulator to Start..."
  while [[ "`netstat -anp | grep 4430 | grep -c ${PID}`" == 0 ]];
    do
      if [ $TIMER -gt 10 ]; then
      echo ""
      echo "VPlex Sim did not start!" >&2
      exit 1
    fi
      printf "."
      sleep $INTERVAL
      let TIMER=TIMER+$INTERVAL
    done
fi # All_Simulators
echo "VPlex Simulator Started"
