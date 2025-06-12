#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
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
  LogTable "$(LogParamsHelp)"
  Log
  LogTable "FILENAME\tA media file.
  LABEL\t(optional) A label to associate with this file.
  \tUsed for display only."
  Log
}

GetDisplayNumber() {
  [ -z "$1" ] && return
  size=$1

  let kb=1024
  let mb=$kb*1024
  let gb=$mb*1024

  if (( $size > $gb )); then
    size="$(( $size / $gb )) GB"
  elif (( $size > $mb )); then
    size="$(( $size / $mb )) MB"
  elif (( $size > $kb )); then
    size="$(( $size / $kb )) KB"
  else
    size+="B"
  fi  
  echo -n "$size"
}

DisplayFileProperties() {
  if [ -r "$file" ]; then 
    [ "$label" ] && nameLine="$label) " || nameLine=""
    nameLine+="$file"

    size="$(ls -l "$file" | awk '{ print $5 }')"
    # For some psychotic reason, the file size gets blown up to its value in bytes
    #   but only when you do this in a script
    #   From the CLI, it works as expected. *sigh*
    size="$(GetDisplayNumber $size)"
  
    info="$(mediainfo "$file")"
    d="$(echo "$info" | grep "Duration" | head -n1 | cut -d: -f2)"
    h="$(echo "$info" | grep "Height" | head -n1 | cut -d: -f2)"
    w="$(echo "$info" | grep "Width" | head -n1 | cut -d: -f2)"
    
    Log "$nameLine"
    LogTable "Size\t $size
Duration\t$d
Height\t$h
Width\t$w"
  else
    LogError "File $file does not exist or is not readable"
    return 1
  fi
}

declare file label

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      $(LogParamsCase))
        ;;
      -h | --help)
        PrintHelp
        exit ;;
      *)
        [ -z "$file" ] && file="$p" || label="$p"
    esac
  done
}

if [ "$BASH_SOURCE" == "$0" ]; then
  ParseCLI "$@"
  DisplayFileProperties
fi
