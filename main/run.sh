#!/bin/bash

loc=$(cat /var/lib/lkp-automation-data/loc)
echo "$loc"
log="/var/log/lkp-automation-data/reboot-log"

STATE_FILE="/var/lib/lkp-automation-data/state-files/main-state"
if [ ! -f $STATE_FILE ]; then
        touch $STATE_FILE
        touch $log
	chmod 666 $STATE_FILE
	chmod 666 $log
        echo "1" > $STATE_FILE 
fi

BASE_LOCAL_VERSION=$(cat /var/lib/lkp-automation-data/state-files/base-kernel-version)
PATCH_LOCAL_VERSION=$(cat /var/lib/lkp-automation-data/state-files/patch-kernel-version)
CURRENT_STATE=$(cat /var/lib/lkp-automation-data/state-files/main-state)

log () {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $log
}

handle_error() {
        log "Error: $1"
        echo "Script failed, Check out the logs in /usr/lib/automation-logs for finding about the error"
        exit 1
}



update_state() {
	chmod 666 $STATE_FILE
	echo "$1" > $STATE_FILE
}

cd $loc || handle_error "Couldn't switch to the directory"
cd .. || handle_error "Couldn't switch to the directory"
log "Enterance of main function"
current_state=$(cat $STATE_FILE)
case $current_state in
	"1")
		name=/boot/vmlinuz-$BASE_LOCAL_VERSION
		grubby --set-default=$name
		chmod 755 $name
		grub2-mkconfig -o /boot/grub2/grub.cfg
		update_state "2"
		log "System about to reboot with base_patches"
		echo "Applied base kernel, BASE_KERNEL:$BASE_LOCAL_VERSION"			
		reboot
		;;
	"2")
		tmp=$(uname -r)
		if [[ "$BASE_LOCAL_VERSION" == "$tmp" ]]; then
			echo "Base kernel is installed on the system, starting the lkp"
		else
			handle_error "Base Kernel is not installed on the system"
		fi
		name2=/boot/vmlinuz-$PATCH_LOCAL_VERSION
		grubby --set-default=$name2
		grub2-mkconfig -o /boot/grub2/grub.cfg
		chmod 755 $name2
		update_state "3"
		echo "Applied kernel with patches, PATCHES_KERNEL:$PATCH_LOCAL_VERSION"
		reboot
		;;
	"3")
		tmp2=$(uname -r)
		if [[ "$PATCH_LOCAL_VERSION" == "$tmp2" ]]; then
			echo "Kernel with patches is installed on the system, starting the lkp"
			#rm $STATE_FILE
			log "SUCCESSFULLY Completed the booting."
			rm $STATE_FILE
			systemctl daemon-reload
			systemctl stop lkp.service
			systemctl disable lkp.service
		else
			echo "couldn't install patches kernel"
			handle_error "Couldn't install patches kernel"
		fi
		;;
esac
