#!/bin/bash

# log handling
log=/usr/lib/reboot_tmp/log
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


# Building the deb-pkg for the built kernel
log "Building debian package for the built kernel...."
make bindeb-pkg -j$(nproc) || handle_error "Building Debian package failed."
log "Successfully built the debian package"
KERNEL_PACKAGE=$(find .. -name "linux-image-[0-9]*-auto-base*.deb" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ") || handle_error "Cannot find kernel with the mentioned specifications. Kernel finding failed."

echo "////////////////////KERNEL_VERSION: $KERNEL_PACKAGE////////////////////////"
