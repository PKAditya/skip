#!/bin/bash

# Graphical Display
pip install pyfiglet &> /dev/null
python3 -m pyfiglet "LKP TESTS"

# Helpers for logs
mkdir /var/log/lkp-automation-data &> /dev/null
mkdir /var/lib/lkp-automation-data &> /dev/null
log=/var/log/lkp-automation-data/pre-reboot-log
touch $log

log () {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}

handle_error() {
        log "Error: $1"
        echo "Script failed, Check out the logs in /var/log/lkp-automation-data/pre-reboot-log for finding about the error"
        exit
}


# capture current working directory
loc=$(pwd)
touch /var/lib/lkp-automation-data/loc
echo $loc > /var/lib/lkp-automation-data/loc
log "Captured current working directory: $loc"
# capture type of distro.
distro=$(cat /etc/os-release | grep ^ID= | cut -d'=' -f2)
user=$(echo $USER)
log "Captured current distro: $distro, current user: $user"

log "Creating a directory for storing the built packages"
if [ ! -d "/var/lib/lkp-automation-data/PACKAGES" ]; then
    sudo mkdir -p /var/lib/lkp-automation-data/PACKAGES
    log "Created a new directory /var/lib/lkp-automation-data/PACKAGES"
else
    log "Directory /var/lib/lkp-automation-data/PACKAGES already exists, deleting the files inside the directory"
    sudo rm -rf /var/lib/lkp-automation-data/PACKAGES/*
fi


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
USER_INPUT=/var/lib/lkp-automation-data/user-input
rm -rf $USER_INPUT &> /dev/null
touch $USER_INPUT
echo "KERNEL_DIR:$KERNEL_DIR" >> $USER_INPUT
echo "BRANCH:$BRANCH" >> $USER_INPUT
echo "BASE_COMMIT:$BASE_COMMIT" >> $USER_INPUT
log "Find the user given input in $USER_INPUT"

# Modifying sudoers 
echo 'Amd$1234!' | sudo -S $loc/sudoers.sh $user || handle_error "Couldn't run sudoers modification script"
echo ""
BASE_LOCAL_VERSION="_base_kernel_$(date +%Y%m%d_%H%M%S)_"
PATCH_LOCAL_VERSION="_patches_kernel_$(date +%Y%m%d_%H%M%S)_"
log "Defined local varibles, BASE_LOCAL_VERSION=$BASE_LOCAL_VERSION and PATCH_LOCAL_VERSION=$PATCH_LOCAL_VERSION"

LOC_FILE=/usr/lib/automation-logs/loc
if [ ! -f "$LOC_FILE" ]; then
	touch $LOC_FILE
fi
echo "$loc" > $LOC_FILE


#create the rpm package of the patches kernel and store it to the /usr/lib/automation-logs/rpms/ for future purpose
cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
log "Navigated to $KERNEL_DIR"
git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."

if [ "$distro" == "ubuntu" ]; then
  if [ "$user" == "amd" ]; then
	  log "Entered directory ubuntu"
          echo 'Amd$1234!' | sudo -S $loc/ubuntu/run.sh $loc $KERNEL_DIR $PATCH_LOCAL_VERSION
  	  log "Created rpm for Patch_kernel"
	  log "Creating rpm for Base_kernel"
	  cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
	  git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
	  git reset --hard $BASE_COMMIT || handle_error "couldn't reset head to the $BASE_COMMIT"
	  echo 'Amd$1234!' | sudo -S $loc/ubuntu/run.sh $loc $KERNEL_DIR $BASE_LOCAL_VERSION
  else
	  log "Entered directory ubuntu"
  	  log "Creating rpm for Patch_kernel"
          sudo $loc/ubuntu/run.sh $loc $KERNEL_DIR $PATCH_LOCAL_VERSION
	  log "Created rpm for Patch_kernel"
          log "Creating rpm for Base_kernel"
          cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
          git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
          git reset --hard $BASE_COMMIT || handle_error "couldn't reset head to the $BASE_COMMIT"
          sudo $loc/ubuntu/run.sh $loc $KERNEL_DIR $BASE_LOCAL_VERSION
  fi
else
  if [ "$user" == "amd" ]; then
	  log "Intializing the steps to build the kernel with patches"
          echo 'Amd$1234!' |  sudo -S $loc/centos/run.sh $loc $KERNEL_DIR $PATCH_LOCAL_VERSION
	  touch /var/lib/lkp-automation-data/state-files/patch-kernel-version
	  cp /var/lib/lkp-automation-data/state-files/kernel-version /var/lib/lkp-automation-data/state-files/patch-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
	  log "Successfully built the kernel patches."
	  log "Intializing the steps to build the base kernel"
          cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
          git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
          git reset --hard $BASE_COMMIT || handle_error "couldn't reset head to the $BASE_COMMIT"
          echo 'Amd$1234!' | sudo -S $loc/centos/run.sh $loc $KERNEL_DIR $BASE_LOCAL_VERSION
	  touch /var/lib/lkp-automation-data/state-files/base-kernel-version
	  cp /var/lib/lkp-automation-data/state-files/kernel-version /var/lib/lkp-automation-data/state-files/base-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
	  log "Successfully built the base kernel"
  else
	  log "Intializing the steps to build the kernel with patches"
          sudo $loc/centos/run.sh $loc $KERNEL_DIR $PATCH_LOCAL_VERSION
	  touch /var/lib/lkp-automation-data/state-files/patch-kernel-version
	  cp /var/lib/lkp-automation-data/state-files/kernel-version /var/lib/lkp-automation-data/state-files/patch-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
	  log "Successfully built the kernel patches."
	  log "Intializing the steps to build the base kernel"
          cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
          git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
          git reset --hard $BASE_COMMIT || handle_error "couldn't reset head to the $BASE_COMMIT"
	  sudo $loc/centos/run.sh $loc $KERNEL_DIR $BASE_LOCAL_VERSION
	  touch /var/lib/lkp-automation-data/state-files/base-kernel-version
          cp /var/lib/lkp-automation-data/state-files/kernel-version /var/lib/lkp-automation-data/state-files/base-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
	  log "Successfully built the base kernel"


  fi
fi



# creating the service file, for running the lkp on both the kernels.

cd $loc/..
git clone https://github.com/PKumarAditya/LKP_Automated.git
cd $loc/LKP_Automated
make
wlkp=$(which lkp)
rlkp="/usr/local/bin/lkp"
whack=$(which hackbench)
rhack="/usr/local/bin/hackbench"
sudo systemctl stop lkprun.service
if [[ ! -x "$rlkp" || ! -x "$rhack" ]]; then
	echo "Either the lkp or hackbench didnot install properly"
	handle_error "Couldn't install lkp or hackbench, install them manually and run the lkp.service file"
fi


rm /var/lib/lkp-automation-data/run.sh
touch /var/lib/lkp-automation-data/run.sh
cp $loc/main/run.sh /var/lib/lkp-automation-data/run.sh
FILE_PATH="/var/lib/lkp-automation-data/run.sh"

sudo touch /var/lib/lkp-automation-data/state-files/main-state
sudo echo "1" > /var/lib/lkp-automation-data/state-files/main-state
# Set the name of the service
SERVICE_NAME="lkp.service"
sudo cp $loc/main/lkp.service /etc/systemd/system/lkp.service

sudo chmod 777 /var/lib/lkp-automation-data/run.sh
sudo chmod 777 /etc/systemd/system/lkp.service
# Reload systemd and start the service
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

echo "Service ${SERVICE_NAME} has been created and started."
