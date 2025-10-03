#!/bin/bash

set -o pipefail

source "${DRB_LIB:-/usr/local/lib}/drbash.sh"

declare APPNAME="process-media"

PrintHelp() {
  tabs 4
  Log "Wrapper script to run media filename normalization and tagging scripts."
  Log
  Log "$(Header "Usage:") $APPNAME [FLAG] [FILE...]"
  Log
  LogHeader "FLAGS: (optional)"
  LogTable "\t-v\tVerbose logging
    \t-vv\tDebug mode
    \t-*\tAnything that is valid for media-fixtitles and media-fixtags."
  Log
  LogTable "$(Header "FILE:")\t(optional) One or more files to process. 
  \tIf the path doesn't start with /, then it will be assumed to be relative to $DRB_MEDIA.
  \tDefault = All files in the \$DRB_MEDIA_STAGING directory."
  Log
  LogHeader "Environment Variables:"
  Log "\tDRB_MEDIA\tThe path of the media archive for this type of media"
  Log "\t\t\t\tIf not set, will be set to the parent of the directory you're running this tool from."
  Log "\tDRB_MEDIA_EXTS\tThe extensions of your media files (without the dot)." 
  Log "\t\t\t\tIf not set, will be set to 'mp4 avi'."
  Log
}

declare -a flags targetFiles

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      -h | ? | --help | --WTF)
        PrintHelp
        exit 0 ;;
      -*)
        flags+=($p) ;;
      *)
        targetFiles+=("$p") ;;
    esac
  done
}

ParseCLI "$@"

if ! CanRun media-fixtitle; then
  LogError "Error: Cannot resolve dependency: media-fixtitle"
  exit 1
fi

if ! CanRun media-fixtags; then
  LogError "Error: Cannot resolve dependency: media-fixtags"
  exit 1
fi

if ! CanRun media-merge; then
  LogError "Error: Cannot resolve dependency: media-merge"
  exit 1
fi

### Filename normalization and compliance
Log "---------------- File Permissions --------------------"

if [ -z "$DRB_MEDIA_USER" ] || [ -z "$DRB_MEDIA_GROUP" ]; then
  LogError "Warning: Your DRB_MEDIA_USER and/or DRB_MEDIA_GROUP variable is not set. File ownership will remain as-is.
  To best ensure success with media processing, set DRB_MEDIA_USER=\"$(whoami)\" and DRB_MEDIA_GROUP=\"users\"
  But if you're sharing these files via Samba, you need to set them to the user and/or group that Samba runs as.
  For example: If your smbd service runs as \"smbadmin\" and that user is in the group \"smbusers\",
    then you can elect to set your user, \"$(whoami)\", as the owner and \'smbusers\' as the group.
    That way, you can process the files and Samba can still share them.
  To not have to do this every time, assign these variables in your media-scripts.conf file.
    export DRB_MEDIA_USER=<username>
    export DRB_MEDIA_GROUP=<groupname>

Do you want to continue with the file ownership as-is [y/N]: "
  read -n1 choice; echo
  if [ "${choice,,}" != 'y' ]; then
    exit 0
  fi
else
  Log "Setting ownership of all files in this directory to $DRB_MEDIA_USER:$DRB_MEDIA_GROUP"
  sudo chown $DRB_MEDIA_USER:$DRB_MEDIA_GROUP *
fi

Log "Setting file permissions in $PWD to (o+rw,g+rw,a+r)"
sudo chmodt f u+rw,g+r,o+r

echo "-------------------- Fix Titles -----------------------"
Run -u media-fixtitle ${flags[@]} "${targetFiles[@]}" || exit $?

echo "--------------------- Fix Tags ------------------------"
Run -u media-fixtags ${flags[@]} "${targetFiles[@]}" || exit $?

# TODO: Auto-tagging via keywords in title

### Deduplication
# TODO: Dedupe by name
# TODO: Dedupe by length

### Indexing
# TODO: Add normalized & deduped title + tags to database for fast searching

Log "---------------- Merge Files Into Repo --------------------"
### Merge files from staging area into main archive
Run -r media-merge "${targetFiles[@]}"
