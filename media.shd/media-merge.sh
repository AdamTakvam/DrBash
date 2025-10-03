#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/drbash.sh"

declare -r APPNAME="media-merge"

CanRun videocomp
if [ $? == 1 ]; then
  LogError "Cannot resolve dependency: videocomp"
  exit 1
fi

PrintHelp() {
  tabs 4
  Log "Moves processed media files from the staging area to the media archive."
  Log
  Log "\tStaging area = PWD = $PWD"
  Log "\tMedia archive = MEDIAREPO = ${MEDIAREPO:-<not set>}"
  Log
  LogTable "$(Header "Usage:")\t$APPNAME [FLAGS] [MEDIA_ARCHIVE]
  \t$APPNAME [FLAGS] [FILE...]
  \t$APPNAME -h"
  Log
  LogHeader "FLAGS:"
  LogTable "$(LogParamsHelp)"
  Log
  LogHeader "Parameters:"
  LogTable "\tMEDIA_ARCHIVE\tLocation of primary long-term media storage.
  \t\tOverrides MEDIAREPO variable value. 
  \tFILE...\tOne or more individual filenames or glob pattern designating a subset of the staging population to be acted upon exclusively."
  Log
  Log "Environment Variables:"
  LogTable "\tMEDIAREPO\tThe location of your main media repositrory
  \tMEDIAEXTS\tA space-delimited list of your media file extensions (default=avi mp4)."
  Log
  LogHeader "Configuration File:"
  Log "\tFor convenience, you may also configure this script via a configuration file. The configuration file must be a Bash-sourcable script simply declaring the names and values of the operative variables used in this script (as listed above)."
  Log "\tConfig file location: ${DRB_DATA}/media-scripts.conf"
  Log "\tExample content:"
  Log "\t\tMEDIAREPO='/path/to/my/media'"
  Log "\t\tMEDIAEXTS='mpeg mp4 avi gif'"
  Log "\tNotes:" 
  Log "\t\t1. The config file location can be controlled by setting the DRB_DATA environment variable." 
  Log "\t\t2. This configuration file is shared with other scripts in this collection and may include more variable definitions than just the ones mentioned here. Just make sure that the ones you need are defined and correct and you can safely ignore any others."
}

_GetMediaFiles() {
  local -n media_files="$1"
  media_files=()

  for ext in "${mediaexts[@]}"; do
    IFS=$'\n' media_files+=($(ls -1 $ext 2>/dev/null))
  done
}

DoMerge() {
  local -r stagingdir="$(realpath "$PWD")"
  [ -z "$mediadir" ] && mediadir="$(realpath "$MEDIAREPO")"
  local -a mediaexts=(${MEDIAEXTS:-avi mp4})
  EditArray -p='*.' mediaexts
  LogVerbose "mediaexts=$(SerializeArray mediaexts)"

  if [ -z "$mediadir" ]; then
    read -p "Provide the fully-qualified path to your media archive directory or just press <enter> to abort: " mediadir
    [ -z "$mediadir" ] && exit 1
    mediadir="$(realpath "$mediadir")"
    export MEDIAREPO="$mediadir"
  fi

  if [[ "$mediadir" == "$stagingdir" ]]; then
    LogError "Error: You must be located in the staging directory, not the media archive directory!"
    return 1
  fi

  read -n1 -p "Are you ready to merge the contents of [$stagingdir] into the main archive [$mediadir] (y/N)? " choice; echo -e "\n"
  
  if [ "${choice,,}" == "y" ]; then 
    local -a files
    _GetMediaFiles "files"
    if [ ${#files[@]} == 0 ]; then
      Log "There doesn't appear to be any media files in this directory.\nRun \"$APPNAME -h\" for more information about how to define your media files.\n"
    else
      LogVerbose "files(${#files[@]}) = $(SerializeArray -e "files")"
      for file in "${files[@]}"; do
        [ "$file" ] && Run mv -n "$file" "$mediadir/"
      done
  
      _GetMediaFiles "files"
      if [ ${#files[@]} != 0 ]; then
        Log "You seem to be conflicted... Oh noes!!
      Fortunately, we've got your back.
      Now let's sort this mess out...\n"
      
        for file1 in "${files[@]}"; do
          file2="$mediadir/$(basename "$file1")"
          
          Run videocomp "$file1" "$file2" 
          
          local -i valid_choice=0
          while [ $valid_choice == 0 ]; do
            valid_choice=1
            Log -n "Which file do you want to $(ColorText LGREEN "KEEP") [1 or 2] or [b]oth or [a]bort? "
            read -n1 choice; echo
            case ${choice,,} in
              1)
                [ "$(LogDebugEnabled)" ] || Journal "Deleting: $file2 by user command"
                rm "$file2" ;;
              2)
                [ "$(LogDebugEnabled)" ] || Journal "Deleting: $file1 by user command"
                rm "$file1" ;;
              b)
                Log "So, you have chosen the number 'both'..."
                Log "To do that, you must choose a new name for the incoming media file."
                Log "Note: Don't be stupid and change it to something that already exists in the destination. We can only hold your hand so much. If you want things to blow up, we'll happily let it.\n"
                if ! EditFilename -r "file1"; then    # Defined in editfilename.sh
                  LogError "So you managed to screw up renaming a file, huh?"
                  LogError "This is not one of your proudest moments in life, is it?"
                  LogError "Don't worry, we're here for you."
                  LogError "We've just taken a picture of your face and emailed to our entire dev team to laugh at."
                  LogError "Just know that we are laughing with you, not at you!"
                  LogError "...Unless you're not laughing. Then we are laughing at you!"
                  return
                fi ;;
              a)
                return ;;
              *)
                valid_choice=0 ;;
            esac
          done
        done
    
        Log "Moving remaining media files into main archive..."
        _GetMediaFiles "files"
        for file in "$files"; do
          Run mv -n "$file" "$mediadir/"
        done
      fi

      _GetMediaFiles "files"
      if [ ${#files[@]} != 0 ]; then
        Log "We tried our best, but you're still conflicted. You might want to consider professional help.\n"
        return 1
      else 
        Log "You are no longer conflicted!\n...You can pay at the front desk on your way out. Cash only!\n"
      fi
    fi

    IFS=$'\n' otherfiles=($(ls))

    if [ "${#otherfiles[@]}" != 0 ]; then
      EditArray -p=$'\t* ' otherfiles
      SerializeArray -e otherfiles
      Log "One more thing! Would you like to delete this other junk you got layin' around in here [y/N]? "
      read -n1 choice; echo
      if [ "${choice,,}" == y ]; then
        for f in "${otherfiles[@]}"; do
          Run rm "$f"
        done
      fi
    fi
  fi
}

declare mediadir=""
declare -a mediaFiles

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      $(LogParamsCase))
        ;;
      -h | --help)
        PrintHelp
        exit ;;
      *)
        if [[ -f "$p" ]]; then
          mediaFiles+="$p"
        elif [[ -d "$p" ]]; then
          if [[ -z "$mediadir" ]]; then
            mediadir="$p" 
          else
            LogError "You may not specify more than one repository location."
            exit 1 
          fi
        else
          LogError "Missing object or unsupported object type: $p"
        fi ;;
    esac
  done
}

if ! IsSourced; then
  ParseCLI "$@"
  DoMerge
fi
