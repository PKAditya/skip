#!/bin/bash

# Check if VM name is provided as argument
if [ $# -ne 1 ]; then
    echo "Error: Please provide VM name as argument"
    echo "Usage: $0 <vm_name>"
    exit 1
fi

vm_name="$1"

# Get list of all VMs
vm_list=$(virsh list --all --name)

# Function to check if exact VM name exists
check_vm() {
    local found=0
    
    # Read the VM list line by line
    while IFS= read -r vm; do
        # Check for exact match using regex anchors ^ and $
        if [[ "$vm" =~ ^${vm_name}$ ]]; then
            found=1
            break
        fi
    done <<< "$vm_list"
    
    if [ $found -eq 0 ]; then
        echo "Error: VM with name '${vm_name}' not found"
        exit 1
    else
        echo "VM '${vm_name}' exists"
        exit 0
    fi
}

# Run the check
check_vm
