#!/bin/bash

LOCAL_VERSION=$1
# log handling
log=/var/log/lkp-automation-data/pre-reboot-log
log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}
handle_error() {
    log "ERROR: $1"
    echo "SETUP Failed, $1"
    echo "for more details refer $log"
    exit 1
}

log "Entered centos/kernel/install.sh script"
# Building the configured kernel
log "Intiated kernel build"
yes "" | make -j$(nproc) || handle_error "Failed to build kernel"
log "Successfully built the kernel"


# Building the rpm for the built kernel
log "Building rpm package for the built kernel...."
make binrpm-pkg -j$(nproc) || handle_error "Building rpm package failed."
log "Successfully built the rpm package"

log "Finding the built rpm location"
KERNEL_PACKAGE=$(find .. -name "kernel-[0-9]*$LOCAL_VERSION*.rpm" -not -name "*devel*" -not -name "*headers*" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ") || handle_error "Cannot find the rpm you are looking for"
log "Found the rpm you are looking for at $KERNEL_PACKAGE"

log "copying the the kernel_package to /var/lib/lkp-automation-data/PACKAGES for further purposes"

cp $KERNEL_PACKAGE /var/lib/lkp-automation-data/PACKAGES


echo "/////////kernel-name: $KERNEL_PACKAGE /////////////////"

log "Installing the built rpm package"
rpm -ivh "$KERNEL_PACKAGE" --force || handle_error "Failed to install the $KERNEL_PACKAGE rpm"
log "Installed the built rpm package"

touch /var/lib/lkp-automation-data/state-files/kernel-package
echo "$KERNEL_PACKAGE" > /var/lib/lkp-automation-data/state-files/kernel-package

log "Grepping for kernel version"
KERNEL_VERSION=$(rpm -qp --queryformat '%{VERSION}\n' "$KERNEL_PACKAGE") || handle_error "Couldn't capture the installed rpm version"
log "Captured kernel version: $KERNEL_VERSION"
rm /var/lib/lkp-automation-data/state-files/kernel-version &> /dev/null
touch /var/lib/lkp-automation-data/state-files/kernel-version
echo "$KERNEL_VERSION" > /var/lib/lkp-automation-data/state-files/kernel-version


echo "version: $KERNEL_VERSION"
grubby --set-default "/boot/vmlinuz-$KERNEL_VERSION" || handle_error "Failed to set default kernel"

grubby --default-kernel

log "Going out of centos/kernel/install.sh script"
