#!/bin/bash

loc=$1
KERNEL_DIR=$2

mkdir /usr/lib/automation-logs/reboot_tmp &> /dev/null
log=/usr/lib/automation-logs/reboot_tmp/log
rm $log &> /dev/null
touch $log

# function defined to log the every step
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}

# function defined to handle error
handle_error() {
	log "ERROR: $1" >> $log
	echo "Refer $log to check the details of the error"
	exit 1
}

# user input for kernel directory
# read -p "Enter the Kernel repository path: " KERNEL_DIR


$loc/ubuntu/kernel/dependencies.sh || handle_error "Failed to run $loc/ubuntu/kernel/dependencies.sh"

if [[ -d $KERNEL_DIR ]]; then
	cd "$KERNEL_DIR"
        log "Directory $KERNEL_DIR exists"
	log "Running the configuration script: $loc/ubuntu/kernel/config.sh"
        $loc/ubuntu/kernel/config.sh $KERNEL_DIR _auto_base_ || handle_error "Failed running $loc/ubuntu/kernel/config.sh"
	log "Successfully ran the configuration"

	log "Proceeding with building the kernel configured with the local version"
	$loc/ubuntu/kernel/install.sh || handle_error "Cannot build the configured kernel."
else
        handle_error "Failed to change to kernel directory, Directory $KERNEL_DIR doesn't exists"
fi

