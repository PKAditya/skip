#!/bin/bash

loc=$1
KERNEL_DIR=$2
LOCAL_VERSION=$3

if [ ! -d /var/lib/lkp-automation-data/state-files ]; then
        mkdir /var/lib/lkp-automation-data/state-files &> /dev/null
fi
touch /var/lib/lkp-automation-data/state-files/kernel_name &> /dev/null

log=/var/log/lkp-automation-data/pre-reboot-log

log() {
	echo "$1" >> log
}
handle_error() {
	echo "ERROR: $1" >> log
	exit 1
}


log "Entered $loc/ubuntu directory"

cd $KERNEL_DIR || handle_error "Couldnt switch to $KERNEL_DIR"
log "current working directory: $KERNEL_DIR"
# running kernel build help script
sudo $loc/ubuntu/kernel/run.sh $loc $KERNEL_DIR $LOCAL_VERSION || handle_error "Failed to run kernel build steps"
log "Going out of ubuntu directory"

# Only added the kernel build helping step
