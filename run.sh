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


if [ ! -d "/usr/lib/automation-logs/PACKAGES" ]; then
    mkdir -p /usr/lib/automation-logs/PACKAGES
else
    sudo rm -rf /usr/lib/automation-logs/PACKAGES/*
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
BASE_LOCAL_VERSION="_base_kernel_"
PATCH_LOCAL_VERSION="_patches_kernel_"

#create the rpm package of the patches kernel and store it to the /usr/lib/automation-logs/rpms/ for future purpose
cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."

if [ "$distro" == "ubuntu" ]; then
  if [ "$user" == "amd" ]; then
	  log "Entered directory ubuntu"
	  log "Creating rpm for Patcj_kernel"
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
	  log "Entered directory centos"
	  log "Creating rpm for Patch_kernel"
          echo 'Amd$1234!' |  sudo -S $loc/centos/run.sh $loc $KERNEL_DIR $PATCH_LOCAL_VERSION
	  cp /usr/lib/automation-logs/state-files/kernel-version /usr/lib/automation-logs/state-files/patch-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
	  # KERNEL_VERSION=$(cat /usr/automation-logs/state-files/kernel-version)
#	  echo KERNEL_VERSION >
	  log "Created rpm for Patch_kernel"
          log "Creating rpm for Base_kernel"
          cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
          git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
          git reset --hard $BASE_COMMIT || handle_error "couldn't reset head to the $BASE_COMMIT"
          echo 'Amd$1234!' | sudo -S $loc/centos/run.sh $loc $KERNEL_DIR $BASE_LOCAL_VERSION
	  cp /usr/lib/automation-logs/state-files/kernel-version /usr/lib/automation-logs/state-files/base-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
	  log "Created the rpm for the base_kernel"
          rm /usr/lib/automation-logs/state-files/main-state &> /dev/null
          touch /usr/lib/automation-logs/state-files/main-state
  else
	  log "Entered directory centos"
	  log "Creating rpm for base_kernel"
          sudo $loc/centos/run.sh $loc $KERNEL_DIR $PATCH_LOCAL_VERSION
	  cp /usr/lib/automation-logs/state-files/kernel-version /usr/lib/automation-logs/state-files/patch-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
	  log "Created rpm for Base_kernel"
          log "Creating rpm for Patch_kernel"
          cd $KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
          git switch $BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
          git reset --hard $BASE_COMMIT || handle_error "couldn't reset head to the $BASE_COMMIT"
	  sudo $loc/centos/run.sh $loc $KERNEL_DIR $BASE_LOCAL_VERSION
	  cp /usr/lib/automation-logs/state-files/kernel-version /usr/lib/automation-logs/state-files/base-kernel-version || handle_error "couldn't copy the installed kernel version to the state_file"
          rm /usr/lib/automation-logs/state-files/main-state &> /dev/null
          touch /usr/lib/automation-logs/state-files/main-state


  fi
fi



# creating the service file, for running the lkp on both the kernels.

rm /usr/lib/automation-logs/run.sh
touch /usr/lib/automation-logs/run.sh
cp $loc/main/run.sh /usr/lib/automation-logs/run.sh
FILE_PATH="/usr/lib/automation-logs/run.sh"

# Set the name of the service
SERVICE_NAME="lkp-auto"

# Create the service file
cat << EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=My Service
After=network.target

[Service]
ExecStart=${FILE_PATH}
Restart=always
User=amd

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start the service
#sudo systemctl daemon-reload
#sudo systemctl start ${SERVICE_NAME}
#sudo systemctl enable ${SERVICE_NAME}

echo "Service ${SERVICE_NAME} has been created and started."
