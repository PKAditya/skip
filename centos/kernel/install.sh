#!/bin/bash

LOCAL_VERSION=$1
# log handling
log=/usr/lib/automation-logs/reboot_tmp/log
log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}
handle_error() {
    log "ERROR: $1"
    echo "SETUP Failed, refer $log for the details"
    exit 1
}

# Building the configured kernel
log "Intiated kernel build"
yes "" | make -j$(nproc) || handle_error "Failed to build kernel"
log "Successfully built the kernel"


# Building the rpm for the built kernel
log "Building debian package for the built kernel...."
make binrpm-pkg -j$(nproc) || handle_error "Building rpm package failed."
log "Successfully built the rpm package"

log "Finding the built rpm location"
KERNEL_PACKAGE=$(find .. -name "kernel-[0-9]*$LOCAL_VERSION*.rpm" -not -name "*devel*" -not -name "*headers*" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ") || handle_error "Cannot find the rpm you are looking for"
log "Found the rpm you are looking for at $KERNEL_PACKAGE"

log "copying the the kernel_package to /usr/lib/automation-logs for further purposes"
# mkdir /usr/lib/automation-logs/RPMS &> /dev/null

if [ ! -d "/path/to/directory" ]; then
    mkdir -p /usr/lib/automation-logs/RPMS
fi
cp $KERNEL_PACKAGE /usr/lib/automation-logs/RPMS/


echo "/////////kernel-name: $KERNEL_PACKAGE /////////////////"

log "Installing the built rpm package"
sudo rpm -ivh "$KERNEL_PACKAGE" --force || handle_error "Failed to install the $KERNEL_PACKAGE rpm"
log "Installed the built rpm package"

touch /usr/lib/automation-logs/state-files/kernel-package
echo "$KERNEL_PACKAGE" > /usr/lib/automation-logs/state-files/kernel-package

log "Grepping for kernel version"
# KERNEL_VERSION=$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' "$KERNEL_PACKAGE") || handle_error "Couldn't capture the installed rpm version"
KERNEL_VERSION=$(rpm -qp --queryformat '%{VERSION}-%{RELEASE}\n' "$KERNEL_PACKAGE") || handle_error "Couldn't capture the installed rpm version"
log "Captured the version of the kernel installed"

echo "version: $KERNEL_VERSION"
sudo grubby --set-default "/boot/vmlinuz-$KERNEL_VERSION" || handle_error "Failed to set default kernel"

sudo grubby --default-kernel
