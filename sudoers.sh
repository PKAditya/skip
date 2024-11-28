#!/bin/bash

# giving the current user root priviledges
user=$1
# echo "$user     ALL=(ALL)       ALL" >> /etc/sudoers

sudoers_pattern="^$user[[:space:]]\+ALL=(ALL)[[:space:]]\+ALL"

if grep -q "$sudoers_pattern" /etc/sudoers; then
    echo "User already has root privileges"
else
    # Create a backup
    cp /etc/sudoers /etc/sudoers.bak
    
    # Create temporary file
    TEMP_SUDOERS=$(mktemp)
    
    # Add the user entry
    cp /etc/sudoers "$TEMP_SUDOERS"
    echo "$user ALL=(ALL) ALL" >> "$TEMP_SUDOERS"
    
    # Verify syntax using visudo
    if visudo -c -f "$TEMP_SUDOERS"; then
        cp "$TEMP_SUDOERS" /etc/sudoers
        echo "Successfully added user to sudoers"
    else
        echo "Error: Syntax check failed. Changes not applied."
        echo "Original sudoers file is unchanged"
    fi
    
    # Clean up
    rm -f "$TEMP_SUDOERS"
fi

# Create a backup of sudoers file
cp /etc/sudoers /etc/sudoers.bak

# Check if /usr/local/bin is already in secure_path
#if grep -q "^Defaults.*secure_path.*\/usr\/local\/bin" /etc/sudoers; then
if grep -q "^Defaults.*secure_path.*/usr/local/bin" /etc/sudoers; then
    echo "/usr/local/bin is already in secure_path"
    exit 0
fi

# Use visudo to check syntax before making changes
TEMP_SUDOERS=$(mktemp)

# Find the secure_path line and modify it
#awk '
#/^Defaults.*secure_path/ {
#    if ($0 !~ /\/usr\/local\/bin/) {
#        # Remove any trailing quotes and add /usr/local/bin
#        gsub(/"$/, "", $0)
#        print $0 ":/usr/local/bin\""
#        next
#    }
#}




awk '
/^Defaults.*secure_path/ {
    if ($0 !~ /\/usr\/local\/bin/) {
        # Remove trailing quote if it exists
        gsub(/"[ ]*$/, "", $0)
        # Remove any spaces at the end
        sub(/[ ]*$/, "", $0)
        # Add /usr/local/bin
        print $0 ":/usr/local/bin"
        next
    }
}
{ print }' /etc/sudoers > "$TEMP_SUDOERS"

# Verify syntax using visudo
if visudo -c -f "$TEMP_SUDOERS"; then
    # If syntax check passes, copy the temp file to sudoers
    cp "$TEMP_SUDOERS" /etc/sudoers
    echo "Successfully added /usr/local/bin to secure_path"
else
    echo "Error: Syntax check failed. Changes not applied."
    echo "Original sudoers file is unchanged"
    rm -f "$TEMP_SUDOERS"
    exit 1
fi

# Clean up
rm -f "$TEMP_SUDOERS"
