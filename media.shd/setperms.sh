#!/bin/bash

# This script is suitable to be run as a cron job
APPNAME="setperms"
config="${USERDATA:-$HOME/.mediadata}/setperms.conf"

Help() {
  tabs 4
  echo "Warning: If you don't know for a fact that you want to run this script, you probably don't!"
  echo
  echo "This command sets ownership and access permissions on all files and directories located in the paths specified in the data file to read-only (ro) or read-rwite (rw), recursively." 
  echo "The execute permission is maintained on all directories, but no execute permission can be set on files."
  echo "This script is intended for use in highly-secured environments where even the user who created certain data may be restricted from modifying it without elevation."
  echo
  echo "Intended Usage Scenario:" 
  echo -e "\tYou have a repository of important but HUGE data files that need to be readable but protected against accidental deletion via user error or virus or malicious script execution or whatever."
  echo -e "\tNormally, periodic backups would be the answer, but this data is in the high terabyte or petabyte range, so that just isn't feasible due to time and bandwidth constraints."
  echo -e "Instead, the data is stored on arrays of 3x+ redundant disks in a data center somewhere underneath the Arizona desert."
  echo -e "And all that protects you from absolute disaster is this Bash script! Are your knuckles white yet? Let's go!"
  echo
  echo "Example Setup:"
  echo -e "\tUser uA is a member of group gA."
  echo -e "\tThey  create some data files in a designated location."
  echo -e "\tAt some point in time, this script is run and the ownership of those files is changed to root:gA and access is changed to 644 (rw-r--r--)."
  echo -e "\tNow, user uA can still read the files by virtue of their membership in gA, but they cannot modify them without elevated permissions via sudo (root user should be a non-login user)".
  echo 
  echo "Result:"
  echo -e "\tIf uA has sudo privilege, then they can still modify files, but at least an extra step must be taken which helps to prevent accidents."
  echo -e "\tIf uA is accessing the data remotely via Samba, then they cannot modify any of the locked files without accessing the file server via ssh and using shell commands which is a much more effective preventative."
  echo -e "\tIf uA doesn't have sudo privilege, then they are unable to modify the locked files by any means."
  echo
  echo "Configuration File: $config" 
  echo -e "\t- If you don't like where it's located, set USERDATA env var to overrride."
  echo -e "\t- Must contain bash-compliant definitions for ro_paths and rw_paths, even if empty."
  echo -e "\t- All path's must be fully-qualified (i.e. must begin with / )"
  echo -e "\t- You may not specify the root as a path."
  echo -e "\t- Technically, the behavior of this script is undefined for paths containing non-file inodes, but it's safe to assume that the result would be terrible."
  echo -e "\t- If the paths overlap, rw permissions will win."
  echo -e "\t\tIn most cases, it only makes sense for rw paths to be a subset of ro paths."
  echo -e "\t\tThis allows you to have writable subfolders like "incoming" as a temporary location to stage new data before it is then moved to the read-only repository."
  echo -e "\tOptionally, the data file may also specify the user and group to assign to the files."
  echo -e "\t\tIf not specified, the script will default to 'root' and 'users'."
  echo -e "\t\tIf those don't exist, then nothing good will happen."
  echo -e "\t\tSo you probably want to specify those values."
  echo
  echo "Configuration File Example:"
  echo -e 
  echo -e "\tsp_user=smbadmin"
  echo -e "\tsp_group=smbusers"
  echo -e "\tdeclare -a ro_paths=("/path/to/something" "path/to/something-else")"
  echo -e "\tdeclare -a rw_paths=("/path/to/something/incoming")"
}

GenConfig() {
  if [ -f "$config" ]; then
    read -n1 -p "Configuration file ($config) exists. Are you sure you want to overwrite it [y/N]? " choice
    [ "${choice,,}" != 'y' ] && exit 0
  fi

  sudo echo "sp_user='root'
sp_group='users'
declare -a ro_paths=()
declare -a rw_paths=()" > "$config"

  echo "Config file created with default values: $config"
}
export -f GenConfig

EnsureConfigExists() {
  if [ ! -r "$config" ]; then
    GenConfig
    return $?
  fi
  return 0
}
export -f EnsureConfigExists

CheckConfigValid() {
  if [ -z "$(declare -p ro_paths 2>/dev/null)" ] || [ -z "$(declare -p rw_paths 2>/dev/null)" ]; then
    echo -e "Error: Configuration file not sourced or does not contain required definitions.\n"
    Help
    return 1
  fi
  return 0
}
export -f CheckConfigValid

# Ensures that data files have consistent ownership and accessibility.
# Intended for data file repositories only.
# Ideal for use as a scheduled cron job

SetPerms() {
  local -n paths="$1"
  let filePerms="${2:-644}"
  let dirPerms=$(( filePerms + 111 ))
  [ -z "$sp_user" ] && sp_user="${3:-root}"
  [ -z "$sp_group" ] && sp_group="${4:-users}"

  for path in "${paths[@]}"
  do
    # Resolve any symlinks and work with the real path.
    path="$(realpath "$path")"

    # Add a really basic handrail (does not avert all possible avenues for disaster)
    # Don't allow path to be root or relative
    if [ "$path" == '/' ] || [ "${path::1}" != '/' ]; then
      echo "Invalid path detected: $path" | logger -s -p user.info
      continue
    fi

    # Sanitize path
    path="$(dirname $path)/$(basename $path)" # Removes trailing slashes and other bullshit

    echo "Resetting permissions for: $path" | logger -s -p user.info

    sudo chown -R "$sp_user:$sp_group" $path/
    sudo chmodt d $dirPerms "$path"
    sudo chmodt f $filePerms "$path/*"
  done
}
export -f SetPerms

OverrideStagingDirs() {
  local -a stagingDirs=(incoming _incoming staging _staging)

  for searchpath in "${ro_paths[@]}"; do
    for dir in "${stagingDirs[@]}"; do
      for path in "$(find "$searchpath" -iname "$dir" -type d)"; do
        echo "Setting staging directory + files + subs to rw: $path" 
        sudo chmodt d 777 "$path"
        sudo chmodt f g+w "$path/*"
      done
    done
  done
}
export -f OverrideStagingDirs

SetPaths() {
  SetPerms "ro_paths" 644
  SetPerms "rw_paths" 664
  OverrideStagingDirs
}
export -f SetPaths

[ "${1,,}" == '-h' ] && { Help; exit 0; }

EnsureConfigExists
[ "$?" == 0 ] || exit 1

source "$config"

CheckConfigValid
[ "$?" == 0 ] || exit 1

if [ -r /usr/bin/time ]; then
  echo "$(/usr/bin/time -f 'Setting permissions complete: %E' bash -c 'SetPaths')" | logger -s -p user.info
else
  echo "Setting permissions complete: $(time SetPaths)" | logger -s -p user.info
fi
