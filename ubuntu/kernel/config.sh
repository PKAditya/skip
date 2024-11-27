#!/bin/bash

log=/usr/lib/reboot_tmp/log
log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}
handle_error() {
    log "ERROR: $1"
    exit 1
}


echo "DIR:$1"
echo "name:$2"
KERNEL_DIR=$1
name=$2


cd $KERNEL_DIR

log "Navigated to the kernel directory"
log "Configuring the kernel..."

# Create a configuration file to build the kernel
make defconfig || handle_error "Failed to create config file"

# Change the local version to our own version
sed -i 's/^CONFIG_LOCALVERSION=.*$/CONFIG_LOCALVERSION="'$name'"/' .config

# Turn off BTF
sed -i 's/^CONFIG_DEBUG_INFO_BTF=.*$/CONFIG_DEBUG_INFO_BTF=n/' .config
if ! grep -q "CONFIG_DEBUG_INFO_BTF=" .config; then
	echo "CONFIG_DEBUG_INFO_BTF=n" >> .config
fi

# Regenerate the old config file so the changes made will take effect
make olddefconfig || handle_error "Failed to update the config file"

log "Kernel configured successfully."
