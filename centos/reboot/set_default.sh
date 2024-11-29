#!/bin/bash

loc=$1
KERNEL_DIR=$2
cd $KERNEL_DIR
KERNEL_PACKAGE=$(cat /usr/lib/automation-logs/state-files/kernel-package)
log=/usr/lib/automation-logs/reboot_logs/reboot-log

log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}

handle_error() {
	log "ERROR: $1" >> $log
	echo "Refer $log regarding details of the error"
	exit 1
}

log "Grepping for kernel version"
# KERNEL_VERSION=$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' "$KERNEL_PACKAGE") || handle_error "Couldn't capture the installed rpm version"
#KERNEL_VERSION=$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}\n' "$KERNEL_PACKAGE") || handle_error "Couldn't capture the installed rpm version"
KERNEL_VERSION=$(rpm -qp --queryformat '%{VERSION}\n' "$KERNEL_PACKAGE") || handle_error "Couldn't capture the installed rpm version"
log "Captured the version of the kernel installed"

touch /usr/lib/automation-logs/state-files/expected-kernel
echo "/boot/vmlinuz-$KERNEL_VERSION" > /usr/lib/automation-logs/state-files/expected-kernel



echo "version: $KERNEL_VERSION"
sudo grubby --set-default "/boot/vmlinuz-$KERNEL_VERSION" || handle_error "Failed to set default kernel"

sudo grubby --default-kernel

