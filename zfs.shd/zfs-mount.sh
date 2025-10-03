#!/bin/bash

set -euo pipefail

source "${DRB_LIB:-/usr/local/lib}/run.sh"

if ! CanSudo; then
  LogError "You must be root or have sudo permissions to run this script."
  exit 1
fi

print_help()
{
  Log "Mounts the specified devices as a ZFS RAID 1 (mirror) set / pool and initializes the file system. Note that this will destroy any data currently on the target disks!"
  Log
  Log "Usage: zfs-mount DEV1 DEV2 [ZPOOL] [MOUNT_POINT]"
  Log
  Log "Parameters:"
  Log "\tDEVx\tThe UUID of a device that will be a member of the new mirror set. It is strongly advised that this parameter be specified as /dev/disk/by-id/scsi-... NOT /dev/sdX."
  Log "\tZPOOL\t(optional) The name of the new mirror set. Default=zfs-pool. If MOUNT_POINT not specified, then this value will also serve as the mount point (i.e. /ZPOOL)."
  Log "\tMOUNT_POINT\t(optional) The path of an empty directory to use as the mount point for the new mirror set."
  Log 
  Log "Note: After the successful creation of the basic mirror set you will be prompted to enter another device if you would like to upgrade to a triple mirror set."
}

format_dev() {
  local -r __path="/dev/disk/by-id"
  local -r dev="$1"
  
  if [ "$dev" ]; then
    [[ "$dev" =~ ^$__path ]] || dev="$__path/$dev"
  fi

  printf "%s" "$dev"
}

create_mirror()
{
  local -r POOL_OPTS="-f -o ashift=12 -O compression=lz4 -O xattr=sa -O canmount=off -O dnodesize=auto -O relatime=on -O mountpoint=$MP"

  DEV1="$(format_dev "$DEV1")"
  DEV2="$(format_dev "$DEV2")"
  
  local -r CREATE_ARGS="$POOL_OPTS $ZPOOL mirror $DEV1 $DEV2"

  Log
  Log "Warning: All data will be destroyed on the specified disks."
  Log
  Log "zpool create $CREATE_ARGS"
  Log
  read -n1 -p "Are you sure you want to continue [y/N]? " RESPONSE; echo

  if [[ ${RESPONSE,,} == y ]]; then
    Run -r zpool create $CREATE_ARGS | LogTee --
  else
    return 2
  fi
}

create_triple_mirror()
{
  read -p "If you would like to upgrade to a triple mirror, enter the Device Id for the third drive now, otherwise, just press <Enter>: " DEV3
  if [ -n "$DEV3" ]; then
    while [[ "$DEV1" =~ $DEV3 ]] || [[ "$DEV2" =~ $DEV3 ]]; do
      read -p "You already specified that disk, big guy. Try again: " DEV3
      [ "$DEV3" ] || return 2;
    done
    
    DEV3="$(format_dev "$DEV3")"
    Run -r zpool attach -f "$ZPOOL" "$DEV1" "$DEV3" | LogTee --
  else
    return 2
  fi
}

create_dataset()
{
  DS="$ZPOOL/share"
  DS_OPTS="-o xattr=sa -o dnodesize=auto -o compression=lz4 -o casesensitivity=mixed"
  if Run -r zfs create $DS_OPTS "$DS" | LogTee --; then
    local -r ACL_OPTS="acltype=nfsv4 xattr=sa aclmode=passthrough aclinherit=passthrough-x $DS"
    Run -r zfs set $ACL_OPTS | LogTee --
  fi
}

if [ -z "${1-}" ] || [ -z "${2-}" ]; then
  print_help
  exit 1
elif [[ "$1" =~ ^-{1,2}h ]]; then
  print_help
  exit 0
fi

DEV1="$1"
DEV2="$2"
ZPOOL="${3:-zfs-pool}"
MP="${4:-/$ZPOOL}"

LogTee "Attempting to create mirror set..."
if create_mirror; then
  LogTee "Mirror set $ZPOOL created successfully!"
  LogTee "Attempting to configure $ZPOOL as a triple mirror..." 
  if create_triple_mirror; then
    LogTee "triple mirror configuration complete!"
    LogTee "Attempting to create ZFS dataset..."
    if create_dataset; then
      LogTee "ZFS dataset created successfully!"
    fi
  fi
fi
