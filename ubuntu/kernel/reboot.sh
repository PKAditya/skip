#!/bin/bash

# User Input

read -p "Enter the Kernel repository path: " KERNEL_DIR

handle_error() {
	log "ERROR: $1"
	exit 1
}

mkdir /usr/lib/reboot_tmp &> /dev/null
log=/usr/lib/reboot_tmp/log
rm $log &> /dev/null
touch $log
loc=$(pwd)


log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}

cd "$KERNEL_DIR" || handle_error "Failed to change to kernel directory"

if [[ -d $KERNEL_DIR ]]; then
	log "Directory $KERNEL_DIR exists"
	$loc/config.sh $KERNEL_DIR base		
else
	handle_error "Directory $KERNEL_DIR doesn't exists"
fi
