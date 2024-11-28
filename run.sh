#!/bin/bash

# Graphical Display
pip install pyfiglet &> /dev/null
python3 -m pyfiglet "LKP TESTS"

# Helpers for logs
mkdir /usr/lib/automation-logs &> /dev/null
log=/usr/lib/automation-logs/log
rm -rf $log &> /dev/null
touch $log

log () {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}

handle_error() {
        log "Error: $1"
        echo "Script failed, Check out the logs in /usr/lib/automation-logs for finding about the error"
        exit
}


# capture current working directory
loc=$(pwd)

# capture type of distro.
distro=$(cat /etc/os-release | grep ^ID= | cut -d'=' -f2)
user=$(echo $USER)

echo "////////////--  STARTING WITH LKP RUNNING  --\\\\\\\\\\\\"
echo "Distro found: $distro"
echo "Current user: $user"
log "Captured distro: $distro and current user: $user"
echo " "

# user input
read -p "Enter kernel repository path: " KERNEL_DIR
log "Captured user input, KERNEL_DIR: $KERNEL_DIR"

# Modifying sudoers 
echo 'Amd$1234!' | sudo -S $loc/sudoers.sh $user || handle_error "Couldn't run sudoers modification script"
log "Modified sudoers"
echo ""


if [ "$distro" == "ubuntu" ]; then
  if [ "$user" == "amd" ]; then
	  log "Entered directory ubuntu"
          echo 'Amd$1234!' | sudo -S $loc/ubuntu/kernel/run.sh $loc $KERNEL_DIR
  else
	  log "Entered directory ubuntu"
          sudo $loc/ubuntu/kernel/run.sh $loc $KERNEL_DIR
  fi
else
  if [ "$user" == "amd" ]; then
	  log "Entered directory centos"
          echo 'Amd$1234!' |  sudo -S $loc/centos/run.sh $user
  else
	  log "Entered directory centos"
          sudo $loc/centos/run.sh $user
  fi
fi
