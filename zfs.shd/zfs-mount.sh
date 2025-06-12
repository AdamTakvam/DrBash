#!/bin/bash

print_help()
{
  echo "Mounts the specified devices as a ZFS RAID 1 (mirror) set / pool and initializes the file system. Note that this will destroy any data currently on the target disks!"
  echo
  echo "Usage: zfs-mount DEV1 DEV2 [ZPOOL] [MOUNT_POINT]"
  echo
  echo "Parameters:"
  echo -e "\tDEVx\tThe UUID of a device that will be a member of the new mirror set. It is strongly advised that this paramater be specified as /dev/disk/by-id/scsi-... NOT /dev/sdX."
  echo -e "\tZPOOL\t(optional) The name of the new mirror set. Default=zfs-pool. If MOUNT_POINT not specified, then this value will also serve as the mount point (i.e. /ZPOOL)."
  echo -e "\tMOUNT_POINT\t(optional) The path of an empty directory to use as the mount point for the new mirror set."
  echo 
  echo "Note: After the successful creation of the 2-way mirror set you will be prompted to enter another device if you would like to upgrade to a 3-way mirror set."
}

create_mirror()
{
  POOL_OPTS="-f -o ashift=12 -O acltype=posixacl -O compression=lz4 -O xattr=sa -O canmount=off -O dnodesize=auto -O relatime=on -O mountpoint=$MP"
  [[ $DEV1 =~ "/dev/" ]] || DEV1="/dev/disk/by-id/$DEV1"
  [[ $DEV2 =~ "/dev/" ]] || DEV2="/dev/disk/by-id/$DEV2"
  ARGS="$POOL_OPTS $ZPOOL mirror $DEV1 $DEV2"

  echo
  echo "Warning: All data will be destroyed on the specified disks."
  echo
  echo "zpool create $ARGS"
  echo
  read -p "Are you sure you want to continue [y/N]? " RESPONSE

  if [[ ${RESPONSE,,} =~ 'y' ]]; then
    OUTPUT=$(sudo zpool create $ARGS | tee $LOG)
    [ $OUTPUT ] || return 0
  fi
  return 1
}

create_3way_mirror()
{
  read -p "If you would like to upgrade to a 3-way mirror, enter the Device Id for the third drive now, otherwise, just press <Enter>: " DEV3
  if [ $DEV3 ]; then
    while [ $DEV3 = $DEV1 -o $DEV3 = $DEV2 ]; do
      read -p "You already specified that disk, big guy. Try again: " DEV3
      if [ ! $DEV3]; then
        break;
      fi
    done
    
    OUTPUT=$(sudo zpool attach -f $ZPOOL $DEV1 $DEV3 | tee -a $LOG)
    [ $OUTPUT ] && return 1
  fi
  return 0
}

create_volume()
{
  VOL="$ZPOOL/share"
  VOL_OPTS="-o xattr=sa -o dnodesize=auto -o compression=lz4 -o casesensitivity=mixed"
  OUTPUT=$(sudo zfs create $VOL_OPTS $VOL | tee -a $LOG)
  [ $OUTPUT ] && return 1 || return 0
}

DEV1=$1
DEV2=$2
ZPOOL=${3:-"zfs-pool"}
MP=${4:-"/$ZPOOL"}

if [ -z $DEV2 ]; then
  print_help
  exit
fi

LOG="/var/log/zfs-create.log"
touch $LOG

echo "Attempting to create mirror set..."
create_mirror
if [ $? = 0 ]; then 
  echo "Mirror set $ZPOOL created successfully!"
  echo "Attempting to configure $ZPOOL as a 3-way mirror..." 
  create_3way_mirror
  if [ $? = 0 ]; then
    echo "3-way mirror configuration complete!"
    echo "Attempting to create ZFS volume..."
    create_volume
    if [ $? = 0 ]; then
      echo "ZFS volume created successfully!"
    fi
  fi
fi
