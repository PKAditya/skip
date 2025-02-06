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


create_vms() {
	n=$2
	VM=$1
	for((i=2; i<=n; i++)); do
		NEW_VM="${VM}${i}"
		log "Creating new vm name $NEW_VM"
		virt-clone --original "$VM" --name "$NEW_VM" --auto-clone || handle_error "Couldn't create new vm named $NEW_VM"
		log "created $NEW_VM successfully"
	done
}

start_vms() {
        n=$2
        VM=$1
        for((i=2; i<=n; i++)); do
                NEW_VM="${VM}${i}"
                virsh start $NEW_VM
		log "Started $NEW_VM successfully"
        done
}

delete_vms() {
        n=$2
        VM=$1
        for((i=2; i<=n; i++)); do
                NEW_VM="${VM}${i}"
                virsh destroy $NEW_VM
                virsh undefine $NEW_VM --remove-all-storage
		log "Deleted $NEW_VM" successfully
        done
}


log "Enterance of main function"
mkdir /var/lib/lkp-automation-data/results
log "created results directory in location /var/lib/lkp-automation-data/results"
OUTPUT_FILE="/var/lib/lkp-automation-data/results/result.csv"
sudo touch $OUTPUT_FILE

VM=$(cat /var/lib/lkp-automation-data/VM)
LKP=$(cat /var/lib/lkp-automation-data/LKP)
n1=$(cat /var/lib/lkp-automation-data/state-files/nvms1)
n2=$(cat /var/lib/lkp-automation-data/state-files/nvms2)



BR1=/var/lib/lkp-automation-data/results/without_vms_base
BR2=/var/lib/lkp-automation-data/results/base_with_5_vms
BR3=/var/lib/lkp-automation-data/results/base_with_10_vms
PR1=/var/lib/lkp-automation-data/results/without_vms_with_patches
PR2=/var/lib/lkp-automation-data/results/patch_with_5_vms
PR3=/var/lib/lkp-automation-data/results/patch_with_10_vms


while true; do
	current_state=$(cat $STATE_FILE)
	case $current_state in
		"1")
			name=/boot/vmlinuz-$BASE_LOCAL_VERSION
			grubby --set-default=$name || handle_error "Couldn't set base kernel as the deafult-kernel"
			chmod 755 $name
			grub2-mkconfig -o /boot/grub2/grub.cfg
			log "System about to reboot with base_patches"
			echo "Applied base kernel, BASE_KERNEL:$BASE_LOCAL_VERSION"			
			rm -rf /lkp/result/hackbench/*
			rm -rf /lkp/result/ebizzy/*
			rm -rf /lkp/result/unixbench/*
			update_state "2"
			reboot
			;;
		"2")
			tmp=$(uname -r)
			if [[ "$BASE_LOCAL_VERSION" == "$tmp" ]]; then
				/var/lib/lkp-automation-data/shutdown-vms.sh
				echo "Base kernel is installed on the system, starting the lkp"
				/var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
				cd /lkp/result/
				BR1=/var/lib/lkp-automation-data/results/without_vms_base
				touch /var/lib/lkp-automation-data/results/without_vms_base
				/lkp/result/result.sh > /var/lib/lkp-automation-data/results/without_vms_base
				awk '{print $0","}' /var/lib/lkp-automation-data/results/without_vms_base >> $OUTPUT_FILE
				virsh destroy $VM
				create_vms $VM $n1
				virsh start $VM
				start_vms $VM $n1
				rm -rf /lkp/result/hackbench/*
				rm -rf /lkp/result/ebizzy/*
				rm -rf /lkp/result/unixbench/*
				/var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                                cd /lkp/result/
				BR2=/var/lib/lkp-automation-data/results/base_with_5_vms
                                touch /var/lib/lkp-automation-data/results/base_with_5_vms
                                /lkp/result/result.sh > /var/lib/lkp-automation-data/results/base_with_5_vms
				/var/lib/lkp-automation-data/shutdown-vms.sh
				delete_vms $VM $n1
				rm -rf /lkp/result/hackbench/*
                                rm -rf /lkp/result/ebizzy/*
                                rm -rf /lkp/result/unixbench/*
				virsh destroy $LKP
				create_vms $LKP $n2
				start_vms $LKP $n2
				virsh start $LKP
				/var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                                cd /lkp/result/
				BR3=/var/lib/lkp-automation-data/results/base_with_10_vms
                                touch /var/lib/lkp-automation-data/results/base_with_10_vms
                                /lkp/result/result.sh > /var/lib/lkp-automation-data/results/base_with_10_vms
                                /var/lib/lkp-automation-data/shutdown-vms.sh
				delete_vms $LKP $n2
				BASE_OUTPUT=/var/lib/lkp-automation-data/results/base-results.csv
				touch $BASE_OUTPUT
				echo "Without vms,with 5 vms,with 10 vms" > $BASE_OUTPUT
				paste -d',' "$BR1" "$BR2" "$BR3" >> $BASE_OUTPUT
				update_state "3"
			else
				handle_error "Base Kernel is not installed on the system"
			fi
			echo "Step-2 done"
			;;
		"3")
			echo "came to step-3"
			name2=/boot/vmlinuz-$PATCH_LOCAL_VERSION
                	grubby --set-default=$name2 || handle_error "Couldn't set kernel with patches as default kernel"
                	grub2-mkconfig -o /boot/grub2/grub.cfg
                	chmod 755 $name2
                	echo "Applied kernel with patches, PATCHES_KERNEL:$PATCH_LOCAL_VERSION"
			rm -rf /lkp/result/hackbench/*
			rm -rf /lkp/result/ebizzy/*
			rm -rf /lkp/result/unixbench/*
			update_state "4"
                	reboot
			;;
	
		"4")
			tmp2=$(uname -r)
			if [[ "$PATCH_LOCAL_VERSION" == "$tmp2" ]]; then
				/var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
				PR1=/var/lib/lkp-automation-data/results/without_vms_with_patches
				touch /var/lib/lkp-automation-data/results/without_vms_with_patches
				cd /lkp/result/
				echo "" > /var/lib/lkp-automation-data/results/without_vms_with_patches 
				/lkp/result/result.sh >> /var/lib/lkp-automation-data/results/without_vms_with_patches
				paste -d '' $OUTPUT_FILE /var/lib/lkp-automation-data/results/without_vms_with_patches > temp.csv && mv temp.csv $OUTPUT_FILE
				
				virsh destroy $VM
				create_vms $VM $n1
				virsh start $VM
				start_vms $VM $n1
				rm -rf /lkp/result/hackbench/*
				rm -rf /lkp/result/ebizzy/*
				rm -rf /lkp/result/unixbench/*
				/var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                                cd /lkp/result/
				PR2=/var/lib/lkp-automation-data/results/patch_with_5_vms
                                touch /var/lib/lkp-automation-data/results/patch_with_5_vms
                                /lkp/result/result.sh > /var/lib/lkp-automation-data/results/patch_with_5_vms
				/var/lib/lkp-automation-data/shutdown-vms.sh
				delete_vms $VM $n1
				rm -rf /lkp/result/hackbench/*
                                rm -rf /lkp/result/ebizzy/*
                                rm -rf /lkp/result/unixbench/*
				virsh destroy $LKP
				create_vms $LKP $n2
				virsh start $LKP
				start_vms $LKP $n2
				/var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                                cd /lkp/result/
				PR3=/var/lib/lkp-automation-data/results/patch_with_10_vms
                                touch /var/lib/lkp-automation-data/results/patch_with_10_vms
                                /lkp/result/result.sh > /var/lib/lkp-automation-data/results/patch_with_10_vms
                                /var/lib/lkp-automation-data/shutdown-vms.sh
				delete_vms $LKP $n2
				PATCH_OUTPUT=/var/lib/lkp-automation-data/results/patch-results.csv
				touch $PATCH_OUTPUT
				echo "Without vms,with 5 vms,with 10 vms" > $PATCH_OUTPUT
				paste -d',' "$PR1" "$PR2" "$PR3" >> $PATCH_OUTPUT
				update_state "5"
				echo "Kernel with patches is installed on the system, starting the lkp"
				log "SUCCESSFULLY Completed the booting."
			else
				echo "couldn't install patches kernel"
				handle_error "Couldn't install patches kernel"
			fi
			;;
		"5")
			rm $STATE_FILE	
			log "kernel is being changed to the kernel before the lkp has been run"
			kernel_nameo=$(cat /var/lib/lkp-automation-data/previous-kernel-name)
			old_kernel=/boot/vmlinuz-$kernel_nameo
			grubby --set-default=$old_kernel || handle_error "Couldn't set the previous kernel as the default kernel"
			base="/boot/vmlinuz-$BASE_LOCAL_VERSION"
			sudo yum remove $base -y
			log "uninstalled the /boot/vmlinuz-$BASE_LOCAL_VERSION kernel image from the system"
			patch="/boot/vmlinuz-$PATCH_LOCAL_VERSION"
			sudo yum remove $patch -y
			log "uninstalled /boot/vmlinuz-$PATCH_LOCAL_VERSION kernel image from the system"
			systemctl daemon-reload
			systemctl stop lkp.service
			reboot
			;;
	esac
	sleep 5
done
