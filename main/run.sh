#!/bin/bash

loc=$(cat /usr/lib/automation-logs/loc)
echo "$loc"
log="/var/log/reboot"

STATE_FILE="/var/lib/reboot"
if [ ! -f $STATE_FILE ]; then
        touch $STATE_FILE
        touch $log
	chmod 666 $STATE_FILE
	chmod 666 $log
        echo "1" > $STATE_FILE 
fi

BASE_LOCAL_VERSION=$(cat /usr/lib/automation-logs/state-files/base-kernel-version)
PATCH_LOCAL_VERSION=$(cat /usr/lib/automation-logs/state-files/patch-kernel-version)
CURRENT_STATE=$(cat /usr/lib/automation-logs/state-files/main-state)

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
		#reboot
		;;
	"2")
		tmp=$(uname -r)
		if [[ "$BASE_LOCAL_VERSION" == "$tmp" ]]; then
			echo "Kernel expected and current matched"
		else
			handle_error "Base Kernel is not installed ono the system"
		fi
		name2=/boot/vmlinuz-$PATCH_LOCAL_VERSION
		grubby --set-default=$name2
		grub2-mkconfig -o /boot/grub2/grub.cfg
		chmod 755 $name2
		update_state "3"
		#reboot
		;;
	"3")
		tmp2=$(uname -r)
		if [[ "$PATCH_LOCAL_VERSION" == "$tmp2" ]]; then
			echo "Patches kernel applied"
			rm $STATE_FILE
			log "SUCCESSFULLY Completed the booting."
		else
			echo "couldn't install patches kernel"
			handle_error "Couldn't install patches kernel"
		fi
		;;
esac
