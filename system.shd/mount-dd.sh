#!/bin/bash

tabs 4
source "${USERLIB:-$HOME/lib}/general.sh"
VERBOSE=1

PrintHelp() {
  echo "Mounts a dd-created image file as a volume on the local file system."
  echo
  echo "Usage: mount-dd [-h] FILE [MOUNT_POINT]"
  echo
  echo "Parameters:"
  echo -e "\t-h\t\t\tPrint this help text."
  echo -e "\tFILE\t\tThe dd-created disk image file."
  echo -e "\tMOUNT_POINT\t(opt) An empty directory where the disk image data will be accessed (default=/mnt/dd-disk)."
  echo
}

[ -z "$1" ] && { PrintHelp; exit 1; }
[[ "$1" =~ ^-h ]] && { PrintHelp; exit 0; }

declare -r file="$1"
declare -r mp="${2:-/mnt/dd-disk}"

[ -r "$file" ] || { LogError "File does not exist or cannot be read"; exit 1; }
[ -d "$mp" ] || Run mkdir -p "$mp"

dev="$(Run losetup --partscan --find --show "$file")"
echo $dev
# Run mount ${dev}p1 "$mp"  # Hardcoding partition 1, waiting to be bitten...
# SysLogTee "Mounted loop device $dev at $mp"
