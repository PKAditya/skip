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
read -p "Enter the branch name with out including the remote repository: " BRANCH
read -p "Enter the commit sha id of the base_kernel: " BASE_COMMIT
log "Captured the user input"

# saving the input to a tmp file
USER_INPUT=/usr/lib/automation-logs/user-input
rm -rf $USER_INPUT &> /dev/null
touch $USER_INPUT
echo "KERNEL_DIR:$KERNEL_DIR" >> $USER_INPUT
echo "BRANCH:$BRANCH" >> $USER_INPUT
echo "BASE_COMMIT:$BASE_COMMIT" >> $USER_INPUT


# Modifying sudoers 
echo 'Amd$1234!' | sudo -S $loc/sudoers.sh $user || handle_error "Couldn't run sudoers modification script"
log "Modified sudoers"
echo ""


#create the rpm package of the patches kernel and store it to the /usr/lib/automation-logs/rpms/ for future purpose
cd KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
git switch BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
LOCAL_VERSION_PATCH="_auto_patch"
if [ "$distro" == "ubuntu" ]; then
  if [ "$user" == "amd" ]; then
	  log "Entered directory ubuntu"
          echo 'Amd$1234!' | sudo -S $loc/ubuntu/run.sh $loc $KERNEL_DIR
  else
	  log "Entered directory ubuntu"
          sudo $loc/ubuntu/run.sh $loc $KERNEL_DIR
  fi
else
  if [ "$user" == "amd" ]; then
	  log "Entered directory centos"
          echo 'Amd$1234!' |  sudo -S $loc/centos/run.sh $loc $KERNEL_DIR
  else
	  log "Entered directory centos"
          sudo $loc/centos/run.sh $loc $KERNEL_DIR
  fi
fi
