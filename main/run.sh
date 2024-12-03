#!/bin/bash

STATE_FILE="/usr/lib/automation-logs/state-files/main-state"
BASE_LOCAL_VERSION=$(cat /usr/lib/automation-logs/state-files/base-kernel-version)
PATCH_LOCAL_VERSION=$(cat /usr/lib/automation-logs/state-files/patch-kernel-version)
CURRENT_STATE=$(cat /usr/lib/automation-logs/state-files/main-state)

log="/usr/lib/automation-logs/main-log"
touch /usr/lib/automation-logs/main-log


