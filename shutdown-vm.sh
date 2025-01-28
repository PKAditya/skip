#!/bin/bash

# Get list of running VMs
running_vms=$(virsh list --name --state-running)

if [ -z "$running_vms" ]; then
    echo "No running VMs found."
    exit 0
fi

# Iterate through each running VM
for vm in $running_vms; do
    echo "Shutting down VM: $vm"
    
    # Attempt graceful shutdown first
    virsh shutdown "$vm"
    
    # Wait up to 60 seconds for VM to shutdown gracefully
    counter=0
    while [ $counter -lt 60 ]; do
        if ! virsh list --name --state-running | grep -q "^$vm$"; then
            echo "VM $vm successfully shut down"
            break
        fi
        sleep 1
        ((counter++))
    done
    
    # If VM is still running after timeout, force shutdown
    if [ $counter -eq 60 ]; then
        echo "Warning: VM $vm did not shutdown gracefully. Forcing shutdown..."
        virsh destroy "$vm"
    fi
done

echo "All VMs have been shut down."
