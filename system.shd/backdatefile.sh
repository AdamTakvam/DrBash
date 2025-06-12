#!/bin/bash

PrintHelp() {
  cmd="$(basename $0)"
  echo "High-level helper script for backdating the modification date of files."
  echo
  echo "Usage: $cmd DATE_PARAM FILENAME"
  echo
  echo "DATE_PARAM:"
  echo -e "\t-d\tNumber of days ago."
  echo -e "\t-f\tUse the modification date of another file."
  echo
  echo -e "FILENAME\tThe name of the file to change the date on."
  echo
  echo "Examples:"
  echo -e "\t$cmd -d 2 myfile.txt"
  echo -e "\t$cmd -f anotherfile.dat myfile.txt"
  echo
}

DateFromDaysAgo() {
  echo "$1 days ago"
}

DateFromRefFile() {
  date -r "$1"
}

SetFileDate() {
  local targetFile="$1"
  local fileDate="$2"

  touch -d "$fileDate" "$targetFile"
}

[ -z "$1" ] && { PrintHelp; exit 1; }
[[ "$1" =~ ^-d ]] && { fileDate="$(DateFromDaysAgo "$2")"; targetFile="$3"; }
[[ "$1" =~ ^-f ]] && { fileDate="$(DateFromRefFile "$2")"; targetFile="$3"; }
[ -z "$fileDate" ] && { PrintHelp; exit 1; }

echo "Old Modification Date: $(date -r "$targetFile")"
SetFileDate "$targetFile" "$fileDate"
echo "New Modification Date: $(date -r "$targetFile")"
