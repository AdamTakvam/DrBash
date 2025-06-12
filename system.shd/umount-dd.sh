#!/bin/bash

tabs 4
source "${USERLIB:-$HOME/lib}/general.sh"
VERBOSE=1

PrintHelp() {
  echo "Unmounts a dd-created mount point and releases the device."
  echo
  echo "Usage: umount-dd [-h] [LOOP_DEVICE]"
  echo
  echo "Parameters:"
  echo -e "\t-h\t\t\tPrint this help text."
  echo -e "\tLOOP_DEVICE\t\t(opt) The mount-dd-created loop device (default: auto-detect and free all)."
  echo -e "\t\t\t\t\tInclude the fully-qualified path (e.g. /dev/loop0)"
  echo
}

[[ "$1" =~ ^-h ]] && { PrintHelp; exit 0; }

declare -r dev="$1"

if [ -z "$dev" ]; then
  for loopDev in /dev/loop*; do
    [[ "$loopDev" =~ control ]] && continue
    Run umount $loopDev
    Run losetup -d $loopDev
    SysLogTee "Released loop device: $loopDev"
  done
else
  [ -e "$dev" ] || { LogError "Device does not exist. Did you specify the full path?"; exit 1; }
  Run umount $dev
  Run losetup -d $dev
fi
