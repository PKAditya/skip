#!/bin/bash

loc=$1
KERNEL_DIR=$2
touch /usr/lib/automation-logs/state-files/reboot
> /usr/lib/automation-logs/state-files/reboot
mkdir /usr/lib/automation-logs/reboot_logs &> /dev/null
rm -rf /usr/lib/automation-logs/reboot_logs/reboot-log &> /dev/null
touch /usr/lib/automation-logs/reboot_logs/reboot-log
log=/usr/lib/automation-logs/reboot_logs/reboot-log

log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}
handle_error() {
	log "ERROR: $1"
	echo "Refer $log for more-details"
	exit 1
}


$loc/centos/reboot/set_default.sh $loc $KERNEL_DIR || handle_error "Failed to run $loc/centos/reboot/set_default.sh"


EXPECTED_KERNEL=$(cat /usr/lib/automation-logs/state-files/expected-kernel)
PRESENT_DEFAULT_KERNEL=$(sudo grubby --default-kernel)

echo "EXPECTED_KERNEL: $EXPECTED_KERNEL"
echo "PRESENT_DEFAULT_KERNEL: $PRESENT_DEFAULT_KERNEL"
if [ "$EXPECTED_KERNEL" = "$PRESENT_DEFAULT_KERNEL" ]; then
	mkdir /usr/lib/automation-logs/rpms &> /dev/null
	KERNEL_PACKAGE=$(cat /usr/lib/automation-logs/state-files/kernel-package)
	cp KERNEL_PACKAGE /usr/lib/automation-logs/rpms/
	log "Kernels matched"
	echo "reboot" > /usr/lib/automation-logs/state-files/reboot
	sudo reboot

else
	echo "Expected and present Default kernel didn't match"
	handle_error "Reboot Failed as the expected and the Default kernel didn't match"
fi
