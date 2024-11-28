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
make -j$(nproc) || handle_error "Failed to build kernel"
log "Successfully built the kernel"


# Building the rpm for the built kernel
log "Building debian package for the built kernel...."
make binrpm-pkg -j$(nproc) || handle_error "Building rpm package failed."
log "Successfully built the rpm package"
