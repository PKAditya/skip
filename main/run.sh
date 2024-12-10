#!/bin/bash

STATE_FILE="/usr/lib/automation-logs/state-files/main-state"

loc=$(cat /usr/lib/automation-logs/loc)
log="/usr/lib/automation-logs/main-log"
if [ ! -f $STATE_FILE ]; then
	touch $STATE_FILE
	touch $log
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
	echo "$1" > $STATE_FILE
}

cd $loc || handle_error "Couldn't switch to the directory"
cd .. || handle_error "Couldn't switch to the directory"

main() {
	current_state=$(cat $STATE_FILE)
	case $current_state in
		"1")
			name=/boot/vmlinuz-$BASE_LOCAL_VERSION
			sudo grubby --set-default=$name
			sudo chmod 755 $name
			sudo grub2-mkconfig -o /boot/grub2/grub.cfg
			update_state "2"
			sudo reboot
			;;
		"2")
			tmp=$(uname -r)
			touch /home/amd/aditya/work
			if [[ "$BASE_LOCAL_VERSION" == "$tmp" ]]; then
				echo "Kernel expected and current matched"
			else
				handle_error "Base Kernel is not installed ono the system"
			fi
			name2=/boot/vmlinuz-$PATCH_LOCAL_VERSION
			sudo grubby --set-default=$name2
			sudo grub2-mkconfig -o /boot/grub2/grub.cfg
			sudo chmod 755 $name2
			update_state "3"
			sudo reboot
			;;
		"3")
			tmp2=$(uname -r)
			touch /home/amd/aditya/work
			if [[ "$PATCH_LOCAL_VERSION" == "$tmp2" ]]; then
				echo "Patches kernel applied" > /home/amd/aditya/work
			else
				echo "couldn't install patches kernel"
				handle_error "Couldn't install patches kernel"
			fi
			sudo rm $STATE_FILE
			;;
	esac
}

main
