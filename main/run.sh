#!/bin/bash

KERNEL_DIR=$1

log=/usr/lib/automation-logs/reboot-twice
rm -rf $log &> /dev/null
touch $log
log() {
	echo "$1" >> log
}
handle_error() {
	log "Error: $1"
	echo "Script failed, refer to $log for more details"
	exit 1
}
read -p "Enter the branch name with out including the remote repository: " BRANCH
read -p "Enter the commit sha id of the base_kernel: " BASE_COMMIT

#create the rpm package of the patches kernel and store it to the /usr/lib/automation-logs/rpms/ for future purpose
cd KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
git switch BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
LOCAL_VERSION_PATCH="_auto_patch"

# Checkout to the base commit and build the rpm package and store it to the /usr/lib/automation-logs/rpms/ for future purposes
cd KERNEL_DIR || handle_error "Failed to navigate to $KERNEL_DIR"
git switch BRANCH || handle_error "Couldn't switch to $BRANCH, aborting...."
LOCAL_VERSION_BASE="_auto_base"
git reset hard $BASE_COMMIT || handle_error "Couldn't reset head to $BASE_COMMIT, aborting...."
