#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
tabs 4

Header() {                                                              
  [ "$1" ] && echo -ne "$(ColorText WHITE "$1")"
}

Table() {
  local td="$1"
  [ -z "$td" ] && { echo; return 0; }
  echo -e "$td" | column -t -s '|'
} 

# Write the header row to stderr to make it easier parse the output in another script
declare report="$(Header "Device Name|Hardware ID|Capacity|Serial Number")\n"

for hdd_id in /dev/disk/by-id/*; do
  
  # Exclude partitions and virtual file systems
  [ "$(echo "$hdd_id" | grep -Ei "part|pve|lvm")" ] && continue

  size="$(sudo fdisk -l $hdd_id | awk '/TiB/ { print $3 }')"
  if [ -z "$size" ]; then                                             
    size="$(sudo fdisk -l $hdd_id | awk '/GiB/ { print $3 }') GB" 
  else                                                                
    size+=" TB"                                                       
  fi
  
  report+="/dev/$(basename "$(readlink "$hdd_id")")|$(basename "$hdd_id")|$size|\n"
done

Table "$report" | sort
# hdparm -I "$hdd_id"
