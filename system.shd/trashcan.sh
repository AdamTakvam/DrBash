#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/run.sh"  # includes general.sh and logging.sh
source "${DRB_LIB:-/usr/local/lib}/arrays.sh" 

Require "trash-cli"

declare -r APPNAME="trashcan"
declare -r APPVERSION="1.0"

Help() {
  tabs 4
  Log "Doing our best to provide an rm-like interface to the recycle / trash bin."
  Log
  Log "Usage: $APPNAME [FLAGS] FILE..."
  Log
  Log "FLAGS:\t(optional) May be specified individually or run together or any combination."
  LogTable "\t-h\tPrint this help screen
  \t-i | -I\tInteractive mode: Prompt before every removal
  \t-r | -R\tRecurse subdirectories (see notes)
  \t-d | -D\tRemove empty directories (overrides -r)
  \t-v\tVerbose logging
  \t-vv\tDebug/Simulation mode (implies -v): Additional verbosity.
  \t-q\tQuiet mode (overrides -v and -vv): Suppress all output.
  \t--\tIndicates that there are no more flags. Any parameters that follow are FILEs.
  \t\tOnly necessary in cases where FILE starts with a hyphen."
  Log
  Log "FILE\tOne or more filenames or a glob patterns with relative or absolute pathing (e.g. media/*.mp4)"
  Log
  Log "Detailed Behavioral Description:"
  Log "* Default behavior:"
  Log "\t- FILE will be matched only against the set of files and file symbolic links in the target path."
  Log "\t- The target path is indicated by FILE. IF FILE doesn't contain a path, the current execution directory (./) is assumed."
  Log "\t- The glob pattern specified in file constrains the deletions to only those file whose names match."
  Log "\t- If FILE is a directory name, then that directory will be removed (if -r specified)."
  Log "\t- If FILE is a directory name followed by / then the behavior is the same as without the /."
  Log "\t- If FILE is a directory name followed by /* then the items in that directory will be acted upon."
  Log "\t- If FILE is just a word or pattern, then the directory is assumed to be ./ (the current directory)."
  Log "\t- FILE may be quoted or unquoted, but be careful as subtle differences may exist!"
  Log "\t- For example:"
  Log "\t    $APPNAME -r "My Documents/*""
  Log "\t                !="
  Log "\t    $APPNAME -r "My Documents"/*"
  Log "\t  ProTip: Shell parameter expansion is the stuff nightmares are made of. Avoid it by enclosing patterns in quotes."
  Log "* Recurse subdirectories (-r):"
  Log "\t- All files and subdirectories of the target path will be moved to trash."
  Log "* Remove empty directories (-d):"
  Log "\t- All files and immediate subdirectories with no contents (including hidden files) will be deleted."
  Log "\t- If combined with -r, then all empty directories anywhere in the subdirectory tree will also be deleted."
  Log "* Interactive mode:"
  Log "\t- Prompts for confirmation before every deletion and whenever there is possibly a choice to be made."
  Log "\t- Confirmation responses include y = Yes; n = No; a = All." 
  Log "\t- Responses are just one letter. Avoid the temptation to press <enter> as that could have unintended consequences."
  Log "\t- The letter in caps is the default if you make any other selection or none (by only pressing <enter>)."
  Log "\t- The default options are what will be chosen if you do not specify interactive mode."
  Log "\t- Note: If you reply with "a" (all), then interactive mode will be disabled for the remainder of the run."
  Log "* Verbose logging:"
  Log "\t- Displays a list of all files to be deleted (after resolving glob patterns). One per line."
  Log "\t- If -i is also specified, a confirmation prompt is included."
  Log "\t- If the file list is more than 50 items long, the list will be truncated with a notice of how many remain undisplayed."
  Log "* Debug/Simulation mode:"
  Log "\t- In addition to maximizing verbosity, simulation mode will prevent any changes to the file system from occuring."
  Log "\t- Instead of deleting files, a notice will be printed detailing the action would have been performed."
  Log "\t- That notice will start with a '>' character and what follows is literally what would be executed in the shell."
  Log "* FILE must be resolvable to real files or links to real files."
  Log "\tTherefore, paths starting with /dev, /proc, /sys, etc are invalid and will be ignored."
  Log "\t\"$APPNAME -r /\" isn't valid either. If you want to wipe out an entire filesystem, go fdisk yourself!"
  Log "* The rm force parameter (-f) is unnecessary since the effect of that flag has been integrated into the default behavior." 
  Log "\t- Use the -i flag to override the force behavior."
  Log "* Regarding the other parameters accepted by rm that do not appear here:"
  Log "\t--one-file-system\tThis is a useful option that we will hopefully see implemented in the future."
  Log "\t---no-preserve-root\tI don't see any compelling reason to implement this."
  Log "\t- Whatever remains is either already covered or excluded by the behaviors described above or it's just odds and ends."
  Log "\t\tNone of it looks like anything that will make or break usability, so consider them low-priority for inclusion here."
  Log "\t\t"Prompt on every third deletion" - What sort of madness is that even?!"
  Log "* To delete a FILE that begins with a hyphen you must ensure that it isn't confused with a flag:"
  Log "\t1. Use the -- flag to indicate the end of flag processing. Or..."
  Log "\t2. Prefix it with a path, even if it's only ./"
}

ProcessFlags() {
  local flags="$1"

  LogDebug "ProcessFlags.Flags: ${flags:-<none>}"

  [[ "${flags,,}" =~ i  ]] && declare -g interactive=1
  [[ "${flags,,}" =~ r  ]] && declare -g recurse=1
  [[ "${flags,,}" =~ d  ]] && declare -g dir=1
  # Note: -v, -vv, and -q are handled by log.sh
}

[ -z "$1" ] && { Help; exit 1; }

declare -a targetPatterns=()

ParseCLI() {
  local flags=''

  for p in "$@"; do 
    if [ $nomoreflags ]; then
      targetPatterns+=("$p")
    else
      case "$p" in
        "" | -h | --help)
          Help
          exit 0 ;;
        --version)
          Log "$APPNAME $APPVERSION"
          trash --version
          exit 0 ;;
        --)
          nomoreflags=1 ;;
        -*)
          # Collate all of the flags together into one string
          flags+=${p:1} ;;
        *)
          targetPatterns+=("$p") ;;
      esac
    fi
  done
  unset p

  ProcessFlags "$flags"

  LogVerbose "Flag.Interactive = ${interactive:-0}"
  LogVerbose "Flag.Recurse = ${recurse:-0}"
}

Delete() {
  local target="$1"
  [ -z "$target" ] && return 0

  # Handrails...
  inodeType=$(stat -c %F -- "$target")
  
  case "$inodeType" in
    "regular file"|"regular empty file"|"directory")
      if [ "$interactive" == 1 ]; then
        Log -n "Are you sure you want to recycle $inodeType $target [Y/n/a]? "
        read -n1 choice; echo
        case "${choice,,}" in
          n)
            return 2 ;;
          a)
            unset interactive ;;
        esac
      fi

      LogVerbose "Recycling $inodeType: $target\n"
      Run -u trash "$target" ;;
    "symbolic link")
      if [ "$interactive" == 1 ]; then
        Run -u /bin/rm -i "$target"
      else
        LogVerbose "$target is a symlink, deleting permanently.\n"
        Run -u /bin/rm -f "$target"
      fi ;;
    *)
      LogError "Error: Unsupported inode type: $inodeType – skipping $target"
      return 1 ;;
  esac
}

ResolveTargets() {
  targetPattern="$1"
  targetDir="$(dirname "$targetPattern")"
  targetDir="${targetDir:-'.'}/"
  targetFile="$(basename "$targetPattern")"
  targetFile="${targetFile:-'*'}" 
  
  LogVerboseError "targetPattern = $targetPattern"
  LogVerboseError "targetDir = $targetDir"
  LogVerboseError "targetFile = $targetFile"

  local findParams=""

  if [ "$targetDir" == '/' ]; then
    return 1
  fi
  
  if [ "$recurse" == 1 ]; then
    findParams='-type f,d,l'
  elif [ "$dir" == 1 ]; then
    findParams='-maxdepth 1 -type f,d,l'
  else
    findParams='-maxdepth 1 -type f,l'
  fi

  if [ "$dir" == 1 ]; then
    findParams+=' -empty'
  fi

  find "$targetDir" $findParams -name "$targetFile"
}

DeletePatterns() {
  for targetPattern in "${targetPatterns[@]}"; do
    targetPattern="$(echo "$targetPattern" | sed 's/"/\\"/g')"  # Escape double-quotes
  
    LogVerbose "Resolving target pattern: $targetPattern"
  
    local -a targets
    mapfile -t targets < <(ResolveTargets "$targetPattern")
    # IFS=$'\n' targets=($(ResolveTargets "$targetPattern"))
    [ "$?" != 0 ] && continue;
    
    if [ "${#targets[@]}" == 0 ]; then
      LogError "$targetPattern not found."
      continue
    fi
  
    # Display the target list
    if [ "$(LogVerboseEnabled)" ]; then
      if (( ${#targets[@]} > 1 )); then
        LogVerbose "Preparing to delete:"
        let imax=${#targets[@]}
        (( $imax > 50 )) && imax=50
        for (( i=0; i<$imax; i++ )); do
          LogVerbose "${targets[$i]}"
        done
      
        if (( ${#targets[@]} > 50 )); then
          let remaining=$(( ${#targets[@]} - 50 ))
          if [ "$interactive" == 1 ]; then
            Log -n "Do you want to see all $remaining files queued for deletion [y/N]? "
            read -n1 choice; echo
            if [ "${choice,,}" == 'y' ]; then
              for (( i=51; i<${#targets[@]}; i++ )); do
                LogVerbose "${targets[$i]}"
              done
            fi
          else
            Log "Plus $remaining more..."
            return 0
          fi
        fi
      fi
    fi
    
    for target in "${targets[@]}"; do
      Delete "$target"
    done
  done
}

ParseCLI "$@"
DeletePatterns
