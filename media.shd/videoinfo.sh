#!/bin/bash

source "$DRB_LIB/drbash.sh"
source "$DRB_MEDIA_LIB/media-props.sh"

Require mediainfo

declare -r APPNAME="videoinfo"

PrintHelp () {
  tabs 4
  Log "Prints the vital statistics about the specified video file"
  Log
  LogTable "$(Header "Usage:")\t$APPNAME [FLAGS] FILENAME [LABEL]
  \t$APPNAME -h"
  Log
  LogHeader "FLAGS:"
  LogTable "\t-c\tCompact listing
  $(LogParamsHelp)"
  Log
  LogTable "FILENAME\tA media file.
  LABEL\t(optional) A label to associate with this file.
  \tUsed for display only."
  Log
}

declare file label 
declare -i compact=0

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      -c)
        compact=1 ;;
      $(LogParamsCase)) ;;
      -h | --help)
        PrintHelp
        exit ;;
      *)
        [ -z "$file" ] && file="$p" || label="$p" ;;
    esac
  done
}

if ! IsSourced; then
  ParseCLI "$@"
  local info="$(mediainfo "$file")"
  if [[ "$?" == 0 ]] && [[ -n "$info" ]]; then
    DisplayMediaProperties "$info" $compact "$label"
  else
    LogError "Failed to get media info for: $file"
    return 2
  fi
fi
