#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/general.sh"

Help() {
  echo
}

Run() {
  local -a poolDisks=()
  local stats="$(zpool status)"
  IFS=$'\n' poolDisks+=($(echo "$stats" | awk '/scsi/ { print $1 }' | cut -d- -f1-2))
  IFS=$'\n' poolDisks+=($(echo "$stats" | awk '/wwn/ { print $1 }' | cut -d- -f1-2))
  
  Log "Installed & Mounted Disks:"
  for disk in "${poolDisks[@]}"; do
    Log "\t$disk"
  done

  local -a availDisks=()
  for aDisk in /dev/disk/by-id/*; do
    aDisk="$(basename "$aDisk")"

    [ "$(echo "$aDisk" | grep -Ei "part|pve|lvm")" ] && continue

    for disk in "${poolDisks[@]}"; do
      if [ "$(echo "$aDisk" | grep "$disk" )" ]; then
        isPool=1
        break
      fi
    done
    [ $isPool ] || availDisks+=("$aDisk")
  done
  
  Log "\nDisks not associated with a ZFS pool:"
  for aDisk in "${availDisks[@]}"; do
    size="$(sudo fdisk -l /dev/disk/by-id/$aDisk | awk '/TiB/ { print $3 }')"
    if [ -z "$size" ]; then
      size="$(sudo fdisk -l /dev/disk/by-id/$aDisk | awk '/GiB/ { print $3 }') GB"
    else
      size+=" TB"
    fi

    Log "\t$aDisk\t$size"
  done
}

Run
