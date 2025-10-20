#!/bin/bash

source "$DRB_LIB/drbash.sh"

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

declare -l tag
declare -i getinfo=0 recurse=0

for p in "$@"; do
  case "$p" in
    "" | -h | ? | --help | WTF)
      PrintHelp
      exit 0 ;;
    -i)
      getinfo=1
      tag="$2" ;;
    -r)
      recurse="1"
      tag="$2" ;;
    *)
      tag="$p" ;;
  esac
done

media_repo="$(ConfigGet_MEDIA_REPO)"

declare -a videos
if (( $recurse )); then
  IFS=$'\n' videos=($(find "${media_repo:-.}/" -type f | grep -E "\[.*[. ]${tag,,}[. ].*\]"))
else
  IFS=$'\n' videos=($(find "${media_repo:-.}/" -maxdepth 1 -type f | grep -E "\[.*[. ]${tag,,}[. ].*\]"))
fi

LogError "Found ${#videos[@]} matches!"

for vid in "${videos[@]}"; do
  Log "$vid"
  if [ "$getinfo" ]; then 
    Log "$(videoinfo "$vid")\n"
  fi
done
