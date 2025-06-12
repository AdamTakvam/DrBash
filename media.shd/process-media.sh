#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
declare APPNANME="process-media"

PrintHelp() {
  tabs 4
  echo "Wrapper script to run media filename normalization and tagging scripts."
  echo
  echo "Usage: $APPNAME [VERSION] [FLAG]"
  echo
  echo "VERSION:" 
  echo -e "\t-d\tRun development versions of media processing scripts (default=stable)"
  echo
  echo "FLAG:"
  echo -e "\t-v\tVerbose logging"
  echo -e "\t-vv\tDebug mode"
  echo
  echo "Environment Variables:"
  echo -e "\tUSERMEDIA\tThe path of the media archive for this type of media"
  echo -e "\t\t\t\tIf not set, will be set to the parent of the directory you're running this tool from."
  echo -e "\tUSERMEDIAEXT\tThe extension of your media files (without the dot)." 
  echo -e "\t\t\t\tIf you have multiple, then you'll have to run this for each extension."
  echo -e "\t\t\t\tIf not set, will be set to 'mp4'."
  echo
}

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      -h | ? | --help)
        PrintHelp
        exit 0 ;;
      -d | d | dev | latest)
        version="-dev" ;;
      -v*)
        flag=$p
    esac
  done
}

ParseCLI "$@"

CanRun media-fixtitle${version}
if [ ! $? ]; then
  LogError "Error: Cannot resolve dependency: media-fixtitle${version}"
  exit 1
fi

CanRun media-fixtags${version}
if [ ! $? ]; then
  LogError "Error: Cannot resolve dependency: media-fixtags${version}"
  exit 1
fi

CanRun media-merge
if [ ! $? ]; then
  LogError "Error: Cannot resolve dependency: media-merge"
  exit 1
fi

### Filename normalization and compliance
Log "---------------- File Permissions --------------------"

if [ -z "$MEDIAUSER" ] || [ -z "$MEDIAGROUP" ]; then
  LogError "Warning: Your MEDIUAUSER and/or MEDIAGROUP variable is not set. File ownership will remain as-is.
  To best ensure success with media processing, set MEDIAUSER=\"$(whoami)\" and USERGROUP=\"users\"
  But if you're sharing these files via Samba, you need to set them to the user and/or group that Samba runs as.
  For example: If your smbd service runs as \"smbadmin\" and that user is in the group \"smbusers\",
    then you can elect to set your user, \"$(whoami)\", as the owner and \'smbusers\' as the group.
    That way, you can process the files and Samba can still share them.
  To not have to do this every time, assign these variables in your .profile or .bashrc file.
    export MEDIAUSER=<username>
    export MEDIAGROUP=<groupname>

Do you want to continue with the file ownership as-is [y/N]: "
  read -n1 choice; echo
  if [ "${choice,,}" != 'y' ]; then
    exit 0
  fi
else
  Log "Setting ownership of all files in this directory to $MEDIAUSER:$MEDIAGRP"
  sudo chown $MEDIAUSER:$MEDIAGRP *
fi

Log "Setting file permissions in $PWD to (o+rw,g+rw,a+r)"
sudo chmodt f u+rw,g+r,o+r *

echo "-------------------- Fix Titles -----------------------"
media-fixtitle${version} $flag
[ $? == 0 ] || exit $?

echo "--------------------- Fix Tags ------------------------"
media-fixtags${version} $flag
[ $? == 0 ] || exit $?

# TODO: Auto-tagging via keywords in title

### Deduplication
# TODO: Dedupe by name
# TODO: Dedupe by length

### Indexing
# TODO: Add normalized & deduped title + tags to database for fast searching

Log "---------------- Merge Files Into Repo --------------------"
### Merge files from staging area into main archive
media-merge
