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
        exit
}

cd $loc || handle_error "Couldn't switch to the directory"
cd .. || handle_error "Couldn't switch to the directory"

