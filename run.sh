#!/bin/bash

# Graphical Display
pip install pyfiglet &> /dev/null
python3 -m pyfiglet "LKP TESTS"

# capture current working directory
loc=$(pwd)

# capture type of distro.
distro=$(cat /etc/os-release | grep ^ID= | cut -d'=' -f2)
user=$(echo $USER)

echo "////////////--  STARTING WITH LKP RUNNING  --\\\\\\\\\\\\"
echo "Distro found: $distro"
echo "Current user: $user"
echo " "

# creating automation logs

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

# user input
read -p "Enter kernel repository path: " KERNEL_DIR


# Modifying sudoers 
echo 'Amd$1234!' | sudo -S $loc/sudoer.sh $user || handle_error "Couldn't run sudoers modification script"

echo ""
if [ "$distro" == "ubuntu" ]; then
  if [ "$user" == "amd" ]; then
          echo 'Amd$1234!' | sudo -S $loc/ubuntu/kernel/run.sh $loc $KERNEL_DIR
  else
          sudo $loc/ubuntu/run.sh $user
  fi
else
  if [ "$user" == "amd" ]; then
          echo 'Amd$1234!' |  sudo -S $loc/centos/run.sh $user
  else
          sudo $loc/centos/run.sh $user
  fi
fi
