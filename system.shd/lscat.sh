#!/bin/bash

shopt -s extglob 

source "${DRB_LIB:-/usr/local/lib}/general.sh"
declare -r APPNAME="lscat"

Help() {
  Log "Displays the contents of all files having names that match the supplied glob expression."
  Log
  LogTable "$(Header "Usage:")\t$APPNAME [FLAGS] [DIR] $(ColorText GRAY '[ | grep -Ei -C1 SEARCH-EXPR ]')
  \t$APPNAME -h"
  Log
  LogHeader "FLAGS"
  LogTable "\t-d\tFollow directory symlinks.
  \t-f\tTreat symlinks to files the same as regular files.
  \t-h\tPrint this help screen.
  $(LogParamsHelp)"
  Log
  LogTable "$(Header "DIR")\tThe base directory you want to search and/or glob expression used to filter the search.
  \tIf not provided, the contents of all files in the current directory and all subdirectories will be displayed."
  Log
  LogTable "$(Header "Notes:")\t$APPNAME will search the specified directory and all of its subdirectories,
  \tbut it will not follow directory symlinks unless the -d flag is specified,
  \tnor will it print the contents of symlinks to files unless the -f flag is specified.
  \tIn no cases will this tool attempt to open non-file-based resources (i.e. /proc/cpuinfo)."
  Log
  LogTable "$(Header "Notes 2:")\tThis tool is basically what 'cat -r' would be if it existed.
  \tIn most cases, you'll want to pipe the output of this command to grep as shown in the 'Usage' line above.
  \tIf you are looking for the flag to prevent this tool from recursing subdirectories, use the command 'cat *'" 
  Log
}

DisplaySeparator() {
  local string="$1"
  for (( i=0; i <= ${#string}; i++ )); do
    echo -n '-'
  done
  echo
}

# Displays the contents of all files matching the supplied glob expression
# + $1 = glob
# - stdout = file(s) contents
CatDir() {
  local workingDir="${1:-$rootDir}"

  LogVerbose "Working directory = $workingDir"
  for file in $workingDir/*; do 
    LogVerbose "Examining inode: $file"
    if [ -z "$file" ] || [ "$file" == '.' ] || [ "$file" == '..' ]; then
      :     # ignore it
    elif [ -d "$file" ]; then
      if [ ! -L "$file" ] || [ $followDirLinks == 1 ]; then
        LogVerbose "Recursing into directory: $file"
        CatDir "$file"
      fi
    elif [ -f "$file" ]; then
      echo -e "\n\n"
      DisplaySeparator "$file"
      echo "$file:"
      DisplaySeparator "$file"
      cat "$file"
    fi
  done
}

declare rootDir="$(realpath "$PWD")"
declare -ig followDirLinks=0 followFileLinks=0

ParseCLI() {
  for p in "$@"; do
    case "$p" in 
      -h)
        Help
        exit 0 ;;
      *($(LogParamsCase))* )
        : ;;
      -d)
        followDirLinks=1 ;;
      -f)
        followFileLinks=1 ;;
      *)
        rootDir="$p" ;;
    esac
  done
}

if [ "$BASH_SOURCE" == "$0" ]; then
  ParseCLI "$@"
  CatDir "$rootDir"
fi
