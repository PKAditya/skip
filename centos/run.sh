#!/bin/bash

loc=$1
KERNEL_DIR=$2
LOCAL_VERSION=$3

# Creating directory to save state files
rm -rf /usr/lib/automation-logs/state-files
mkdir /usr/lib/automation-logs/state-files
touch /usr/lib/automation-logs/state-files/kernel_name


# log handling
rm -rf /usr/lib/automation-logs/centos-log
touch /usr/lib/automation-logs/centos-log
log=/usr/lib/automation-logs/centos-log

log() {
	echo "$1" >> log
}
handle_error() {
	echo "ERROR: $1" >> log
	exit 1
}

cd $KERNEL_DIR || handle_error "Couldnt switch to $KERNEL_DIR"
# running kernel build help script
sudo $loc/centos/kernel/run.sh $loc $KERNEL_DIR $LOCAL_VERSION || handle_error "Failed to run kernel build steps"


# running the reboot process
# sudo $loc/centos/reboot/run.sh $loc $KERNEL_DIR || handle_error "Failed to process the reboot"
