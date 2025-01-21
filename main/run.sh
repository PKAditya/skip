#!/bin/bash

loc=$(cat /var/lib/lkp-automation-data/loc)
echo "$loc"
log="/var/log/lkp-automation-data/reboot-log"

STATE_FILE="/var/lib/lkp-automation-data/state-files/main-state"
if [ ! -f $log ]; then
	touch $log
	chmod 666 $log
fi
if [ ! -f $STATE_FILE ]; then
#        touch $STATE_FILE
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

log "Enterance of main function"
while true; do
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
				# systemctl start lkprun.service
                                rm -rf /lkp/result/hackbench/*
                                rm -rf /lkp/result/ebizzy/*
                                rm -rf /lkp/result/unixbench/*
				/var/lib/lkprun.sh
				# echo "3" > /var/lib/lkp-automation-data/state-files/main-state
				cd /lkp/result/
				mkdir /var/lib/lkp-automation-data/results
				touch /var/lib/lkp-automation-data/results/without_vms_base
				/lkp/result/result.sh > /var/lib/lkp-automation-data/results/without_vms_base
				update_state "3"
			else
				handle_error "Base Kernel is not installed on the system"
			fi
			echo "Step-2 done"
			;;
		"3")
			echo "came to step-3"
			name2=/boot/vmlinuz-$PATCH_LOCAL_VERSION
                	grubby --set-default=$name2
                	grub2-mkconfig -o /boot/grub2/grub.cfg
                	chmod 755 $name2
                	update_state "4"
                	echo "Applied kernel with patches, PATCHES_KERNEL:$PATCH_LOCAL_VERSION"
                	reboot
			;;
	
		"4")
			tmp2=$(uname -r)
			if [[ "$PATCH_LOCAL_VERSION" == "$tmp2" ]]; then
				# systemctl start lkprun.service
				rm -rf /lkp/result/hackbench/*
				rm -rf /lkp/result/ebizzy/*
				rm -rf /lkp/result/unixbench/*
				/var/lib/lkprun.sh
				touch /var/lib/lkp-automation-data/results/without_vms_with_patches
				cd /lkp/result/
				/lkp/result/result.sh > /var/lib/lkp-automation-data/results/without_vms_with_patches
                        	#echo "5" > /var/lib/lkp-automation-data/state-files/main-state
				update_state "5"
				echo "Kernel with patches is installed on the system, starting the lkp"
				# systemctl start lkprun.service
				#rm $STATE_FILE
				log "SUCCESSFULLY Completed the booting."
				# rm $STATE_FILE
			else
				echo "couldn't install patches kernel"
				handle_error "Couldn't install patches kernel"
			fi
			;;
		"5")
			rm $STATE_FILE	
			systemctl daemon-reload
			systemctl stop lkp.service	
			;;
	esac
	sleep 5
done
