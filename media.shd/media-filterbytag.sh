#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"

declare -r APPNAME="filterbytag"

PrintHelp() {
  tabs 4
  echo "Finds all video files in the current directory tree that match the supplied glob pattern along with detailed media attributes for each result."
  echo
  echo "Usage: $APPNAME [OPT] TAG"
  echo
  echo -e "OPT\t\t\t(Optional) Operational flags (only use one)"
  echo -e "\t-h or ?\tPrint this help screen."
  echo -e "\t-i\t\tGet basic media info for each file (resolution + duration)"
  echo -e "\t-r\t\tRecurse subdirectories"
  echo -e "TAG\t\t\tAny fully-qualified tag name (e.g. historical.drama)."
  echo
}

declare -l tag="$1"

if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "?" ]; then
  PrintHelp
  exit 0
elif [ "$1" == "-i" ]; then
  getinfo=1
  tag="$2"
elif [ "$1" == "-r" ]; then
  rparam="1"
  tag="$2"
fi

declare -a videos
if [ "$rparam" ]; then
  IFS=$'\n'; videos=($(find . -name "*${tag,,}*" -type f))
else
  IFS=$'\n'; videos=($(find . -maxdepth 1 -name "*${tag,,}*" -type f))
fi

LogError "Found ${#videos[@]} matches!"

for vid in "${videos[@]}"; do
  Log "$vid"
  if [ "$getinfo" ]; then 
    Log "$(videoinfo "$vid")\n"
  fi
done
