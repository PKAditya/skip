#!/bin/bash

loc=$1
KERNEL_DIR=$2

# log handling
rm -rf /usr/lib/automation-logs/ubuntu-log
touch /usr/lib/automation-logs/ubuntu-log
log=/usr/lib/automation-logs/ubuntu-log

log() {
	echo "$1" >> log
}
handle_error() {
	echo "ERROR: $1" >> log
	exit 1
}


# running kernel build help script
sudo $loc/ubuntu/kernel/run.sh $loc $KERNEL_DIR || handle_error "Failed to run kernel build steps"


# Only added the kernel build helping step
