#!/bin/bash

loc=$(cat /var/lib/lkp-automation-data/loc)
echo "$loc"
log="/var/log/lkp-automation-data/reboot-log"

STATE_FILE="/var/lib/lkp-automation-data/state-files/main-state"
SUB_STATE_FILE="/var/lib/lkp-automation-data/state-files/sub-state"

# creation of log and state_files, if they do not exist
if [ ! -f $log ]; then
    touch $log
    chmod 666 $log
fi
if [ ! -f $STATE_FILE ]; then
    touch $STATE_FILE
    chmod 666 $STATE_FILE
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
    echo "Script failed, Check out the logs in $log for finding about the error"
    exit 1
}

update_state() {
    chmod 666 $STATE_FILE
    echo "$1" > $STATE_FILE
}

update_sub_state() {
    chmod 666 $SUB_STATE_FILE
    echo $1 > $SUB_STATE_FILE
}

create_vms() {
    n=$2
    VM=$1
    for((i=2; i<=n; i++)); do
        NEW_VM="${VM}${i}"
        log "Creating new vm name $NEW_VM"
        virt-clone --original "$VM" --name "$NEW_VM" --auto-clone 
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
        log "Deleted $NEW_VM successfully"
    done
}

# Function to set default kernel in Ubuntu
set_default_kernel() {
    local kernel_version=$1
    # Update GRUB default entry
    sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Ubuntu>Ubuntu, with Linux ${kernel_version}\"/" /etc/default/grub
    update-grub
    log "Set kernel ${kernel_version} as default"
}

#checking for the existence of results directory
log "Entrance of main function"
mkdir -p /var/lib/lkp-automation-data/results
log "created results directory in location /var/lib/lkp-automation-data/results"

VM=$(cat /var/lib/lkp-automation-data/VM)
LKP=$(cat /var/lib/lkp-automation-data/LKP)
n1=$(cat /var/lib/lkp-automation-data/state-files/nvms1)
n2=$(cat /var/lib/lkp-automation-data/state-files/nvms2)

# Add these checks after the initial state file checks
if [ ! -f "/var/lib/lkp-automation-data/VM" ]; then
    handle_error "VM configuration file not found"
fi
if [ ! -f "/var/lib/lkp-automation-data/LKP" ]; then
    handle_error "LKP configuration file not found"
fi
if [ ! -f "/var/lib/lkp-automation-data/state-files/nvms1" ]; then
    handle_error "nvms1 configuration file not found"
fi
if [ ! -f "/var/lib/lkp-automation-data/state-files/nvms2" ]; then
    handle_error "nvms2 configuration file not found"
fi

TS=/var/lib/lkp-automation-data/results/test_suites
BR1=/var/lib/lkp-automation-data/results/Base-without_vms
BR2=/var/lib/lkp-automation-data/results/Base-with_vms
BR3=/var/lib/lkp-automation-data/results/Base-with_lkp_vms
PR1=/var/lib/lkp-automation-data/results/Patch-without_vms
PR2=/var/lib/lkp-automation-data/results/Patch-with_vms
PR3=/var/lib/lkp-automation-data/results/Patch-with_lkp_vms

while true; do
    current_state=$(cat $STATE_FILE)
    case $current_state in
        "1")
            set_default_kernel $BASE_LOCAL_VERSION || handle_error "Couldn't set base kernel as the default kernel"
            chmod 755 /boot/vmlinuz-$BASE_LOCAL_VERSION
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
                if [ ! -f "$SUB_STATE_FILE" ]; then
                    touch $SUB_STATE_FILE
                    chmod 666 $SUB_STATE_FILE
                    echo "1" > $SUB_STATE_FILE
                fi
                while true; do
                    current_sub_state=$(cat $SUB_STATE_FILE)
                    case $current_sub_state in
                        "1")
                            /var/lib/lkp-automation-data/shutdown-vms.sh
                            echo "Base kernel is installed on the system, starting the lkp"
                            /var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                            touch $BR1
                            echo "Base-Without vms" > $BR1
                            cat /lkp/result/test.result >> $BR1 
                            update_sub_state "2"
                            ;;
                        "2")
                            virsh destroy $VM
                            create_vms $VM $n1
                            virsh start $VM
                            start_vms $VM $n1
                            rm -rf /lkp/result/hackbench/*
                            rm -rf /lkp/result/ebizzy/*
                            rm -rf /lkp/result/unixbench/*
                            /var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                            touch $BR2
                            echo "Base-With $n1 vms" > $BR2
                            cat /lkp/result/test.result >> $BR2
                            /var/lib/lkp-automation-data/shutdown-vms.sh
                            delete_vms $VM $n1
                            update_sub_state "3"
                            ;;
                        "3")
                            rm -rf /lkp/result/hackbench/*
                            rm -rf /lkp/result/ebizzy/*
                            rm -rf /lkp/result/unixbench/*
                            virsh destroy $LKP
                            create_vms $LKP $n2
                            start_vms $LKP $n2
                            virsh start $LKP
                            /var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                            touch $BR3 
                            echo "Base-With $n2 lkp vms" > $BR3
                            cat /lkp/result/test.result >> $BR3
                            /var/lib/lkp-automation-data/shutdown-vms.sh
                            delete_vms $LKP $n2
                            BASE_OUTPUT=/var/lib/lkp-automation-data/results/base-results.csv
                            touch $BASE_OUTPUT
                            paste -d',' "$BR1" "$BR2" "$BR3" >> $BASE_OUTPUT
                            update_state "3"
                            rm -rf $SUB_STATE_FILE
                            break
                            ;;
                    esac
                    sleep 5
                done
            else
                handle_error "Base Kernel is not installed on the system"
            fi
            echo "Step-2 done"
            ;;
        "3")
            echo "came to step-3"
            set_default_kernel $PATCH_LOCAL_VERSION || handle_error "Couldn't set kernel with patches as default kernel"
            chmod 755 /boot/vmlinuz-$PATCH_LOCAL_VERSION
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
                if [ ! -f "$SUB_STATE_FILE" ]; then
                    touch $SUB_STATE_FILE
                    chmod 666 $SUB_STATE_FILE
                    echo "1" > $SUB_STATE_FILE
                fi
                while true; do
                    current_sub_state=$(cat $SUB_STATE_FILE)
                    case $current_sub_state in
                        "1")
                            /var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                            touch $PR1
                            echo "Patch-without vms" > $PR1
                            cat /lkp/result/test.result >> $PR1
                            update_sub_state "2"
                            ;;
                        "2")
                            virsh destroy $VM
                            create_vms $VM $n1
                            virsh start $VM
                            start_vms $VM $n1
                            rm -rf /lkp/result/hackbench/*
                            rm -rf /lkp/result/ebizzy/*
                            rm -rf /lkp/result/unixbench/*
                            /var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                            touch "$PR2"
                            echo "Patch-with $n1 vms" > $PR2
                            cat /lkp/result/test.result >> $PR2 
                            /var/lib/lkp-automation-data/shutdown-vms.sh
                            delete_vms $VM $n1
                            update_sub_state "3"
                            ;;
                        "3")
                            rm -rf /lkp/result/hackbench/*
                            rm -rf /lkp/result/ebizzy/*
                            rm -rf /lkp/result/unixbench/*
                            virsh destroy $LKP
                            create_vms $LKP $n2
                            virsh start $LKP
                            start_vms $LKP $n2
                            /var/lib/lkprun.sh || handle_error "Problem with running the lkp-tests"
                            touch $PR3
                            echo "Patch-with $n2 lkp vms" > $PR3 
                            cat /lkp/result/test.result >> $PR3
                            /var/lib/lkp-automation-data/shutdown-vms.sh
                            delete_vms $LKP $n2
                            PATCH_OUTPUT=/var/lib/lkp-automation-data/results/patch-results.csv
                            touch $PATCH_OUTPUT
                            echo "Without vms,with $n1 vms,with $n2 vms" > $PATCH_OUTPUT
                            paste -d',' "$PR1" "$PR2" "$PR3" >> $PATCH_OUTPUT
                            echo "Kernel with patches is installed on the system, starting the lkp"
                            log "SUCCESSFULLY Completed the booting."
                            rm $SUB_STATE_FILE
                            update_state "5"
                            break
                            ;;
                    esac
                    sleep 5
                done
            else
                echo "couldn't install patches kernel"
                handle_error "Couldn't install patches kernel"
            fi
            ;;
        "5")
            /var/lib/lkp-automation-data/shutdown-vms.sh
            python3 /var/lib/lkp-automation-data/results/excel-generator.xlsx
            rm $STATE_FILE
            rm $SUB_STATE_FILE    
            log "kernel is being changed to the kernel before the lkp has been run"
            kernel_nameo=$(cat /var/lib/lkp-automation-data/previous-kernel-name)
            set_default_kernel $kernel_nameo || handle_error "Couldn't set the previous kernel as the default kernel"
            
            # Remove kernels using apt instead of yum
            apt-get remove linux-image-$BASE_LOCAL_VERSION -y
            log "uninstalled the linux-image-$BASE_LOCAL_VERSION kernel image from the system"
            apt-get remove linux-image-$PATCH_LOCAL_VERSION -y
            log "uninstalled linux-image-$PATCH_LOCAL_VERSION kernel image from the system"
            apt-get autoremove -y
            reboot
            ;;
    esac
    sleep 5
done
