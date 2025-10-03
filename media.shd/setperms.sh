#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/logging.sh"

# This script is suitable to be run as a cron job
declare -r APPNAME="setperms"
declare -r CONFIGFILE="$DRB_DATA/media-scripts.conf"
declare -r DEFAULT_USER='root'
declare -r DEFAULT_GROUP='users'
declare -ir DEFAULT_PERMS=644
declare -ar RO_PATHS=('/porn' '/media-share')
declare -ar RW_PATHS=('/share' '/porn/new')

Help() {
  tabs 4
  LogColor RED "Warning: If you don't know for a fact that you want to run this script, you probably don't!"
  Log
  Log "This command sets ownership and access permissions on all files and directories located in the paths specified in the data file to read-only (ro) or read-write (rw), recursively." 
  Log "The execute permission is maintained on all directories, but no execute permission can be set on files."
  Log "This script is intended for use in highly-secured environments where even the user who created certain data may be restricted from modifying it without elevation."
  Log
  LogHeader "Intended Usage Scenario:" 
  Log "\tYou have a repository of important but HUGE data files that need to be readable but protected against accidental deletion via user error or virus or malicious script execution or whatever."
  Log "\tNormally, periodic backups would be the answer, but this data is in the high terabyte or petabyte range, so that just isn't feasible due to time and bandwidth constraints."
  Log "Instead, the data is stored on arrays of 3x+ redundant disks in a data center somewhere underneath the Arizona desert."
  Log "And all that protects you from absolute disaster is this Bash script! Are your knuckles white yet? Let's go!"
  Log
  LogHeader "Example Setup:"
  Log "\tUser uA is a member of group gA."
  Log "\tThey  create some data files in a designated location."
  Log "\tAt some point in time, this script is run and the ownership of those files is changed to root:gA and access is changed to 644 (rw-r--r--)."
  Log "\tNow, user uA can still read the files by virtue of their membership in gA, but they cannot modify them without elevated permissions via sudo (root user should be a non-login user)".
  Log 
  LogHeader "Result:"
  Log "\tIf uA has sudo privilege, then they can still modify files, but at least an extra step must be taken which helps to prevent accidents."
  Log "\tIf uA is accessing the data remotely via Samba, then they cannot modify any of the locked files without accessing the file server via ssh and using shell commands which is a much more effective preventative."
  Log "\tIf uA doesn't have sudo privilege, then they are unable to modify the locked files by any means."
  Log
  LogHeader "Configuration:" 
  LogTable "\t- Edit this script to configure it. This script doesn't source from global configuration intentionally.
  \t- Must contain bash-compliant definitions for RO_PATHS and RW_PATHS, even if empty.
  \t- All path's must be fully-qualified (i.e. must begin with / )
  \t- You may not specify the root as a path.
  \t- Technically, the behavior of this script is undefined for paths containing non-file inodes, but it's safe to assume that the result would be terrible.
  \t- If the paths overlap, rw permissions will win.
  \t    In most cases, it only makes sense for RW_PATHS to be a subset of RO_PATHS.
  \t- All files and directories in either path list will be assigned ownership to \$DRB_MEDIA_USER and \$DRB_MEDIA_GROUP
  \t    These values are set in the global configuration file: $(GlobalConfigFile)" 
  Log
  LogHeader "Regardless of What You Configure..."
  LogTable "\t- All subdirectories of RO_PATHS starting with an underscore (_) or named 'incoming', 'staging', or 'unsorted' will be set to rw.
  \t- The \$DRB_MEDIA_REPO directory will be set to ro.
  \t- The \$DRB_MEDIA_STAGING directory will be set to rw."
  Log
}

# Ensures that data files have consistent ownership and accessibility.
# Intended for data file repositories only.
# Ideal for use as a scheduled cron job

SetPerms() {
  local -n paths="$1"
  local -i filePerms="${2:-$DEFAULT_PERMS}"
  local -i dirPerms=$(( filePerms + 111 ))
  local user="$(ConfigGet_MEDIA_USER)"
  local group="$(ConfigGet_MEDIA_GROUP)"
  

  for path in "${paths[@]}"; do
    # Resolve any symlinks and work with the real path.
    path="$(realpath "$path")"

    # Add a really basic handrail (does not avert all possible avenues for disaster)
    # Don't allow path to be root or relative
    if [ "$path" == '/' ] || [ "${path::1}" != '/' ]; then
      LogTee "Invalid path detected: $path"
      continue
    fi

    # Sanitize path
    path="$(dirname "$path")/$(basename "$path")" # Removes trailing slashes and other bullshit

    LogTee "Resetting permissions for: $path"

    sudo chown -R "$user:$group" $path/
    sudo chmodt d $dirPerms "$path"
    sudo chmodt f $filePerms "$path/*"
  done
}

OverrideStagingDirs() {
  local -a stagingDirs=( _* incoming staging unsorted )

  for searchpath in "${RO_PATHS[@]}"; do
    for dir in "${stagingDirs[@]}"; do
      for path in "$(find "$searchpath" -iname "$dir" -type d)"; do
        echo "Setting staging directory + files + subs to rw: $path" 
        sudo chmodt d 777 "$path"
        sudo chmodt f g+w "$path/*"
      done
    done
  done
}

SetPaths() {
  RO_PATHS+=("$(ConfigGet_MEDIA_REPO)")
  RW_PATHS+=("$(ConfigGet_MEDIA_STAGING)")

  SetPerms "RO_PATHS" 664
  SetPerms "RW_PATHS" 666
  
  OverrideStagingDirs
}

[ "${1,,}" == '-h' ] && { Help; exit 0; }

if [ -r /usr/bin/time ]; then
  LogTee "$(/usr/bin/time -f 'Setting permissions complete: %E' bash -c 'SetPaths')"
else
  LogTee "Setting permissions complete: $(time SetPaths)"
fi
