#!/bin/bash

source "${USERLIB:-$HOME/lib}/run.sh"
source "${USERLIB:-$HOME/lib}/arrays.sh"

CanRun videoinfo
if [ ! $? ]; then
  LogError "Error: Cannot resolve dependency: videoinfo"
  exit 1
fi

declare -r APPNAME="videocomp"

PrintHelp () {
  tabs 4
  Log "Display metadata about video files."
  Log
  LogTable "$(Header "Usage:")\t$APPNAME FILE...
  \t$APPNAME -h"
  Log
  Log -e "FILE\tAny media file (specify at least twice)"
  Log
}

CompareFiles() {
  for (( i=0; i<${#files[@]}; i++ )); do
    f="${files[$i]}"
    Run videoinfo "$f" $(( i+1 ))
  done
  return $?
}

declare -a files=()

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      "" | -h | --help)
        PrintHelp 
        exit ;;
      *)
        files+=("$p") ;;
    esac
  done
}

# Don't run if we're being sourced
if [ "$BASH_SOURCE" == "$0" ]; then
  ParseCLI "$@"
  CompareFiles
fi

