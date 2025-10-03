#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/general.sh"
declare -r APPNAME=="rmlt"

PrintHelp() {
  echo "Deletes the specified file if its size is below the specified threshold value."
  echo
  echo "Usage: $APPNAME [FLAGS] FILE THRESHOLD"
  echo
  echo -e "FLAGS:"
  echo -e "\t-h\tShow this help screen"
  echo -e "\t-v\tVerbose output"
  echo -e "\t-vv\tDebug mode"
  echo
  echo -e "FILE\tThe name of the file to conditionally delete. This parameter can be a glob (e.g. *.mp4)."
  echo
  echo -e "THRESHOLD\tThe minimum size (in KB) the file must be in order to avoid being deleted."
}

while [ "$1" ]; do
  case "$1" in
    -h)
      PrintHelp
      exit 1 ;;
    -v)
      LogEnableVerbose
      shift ;;
    -vv)
      LogEnableDebug
      shift ;;
    *)
      [ -z "$filename" ] \
        && declare -r filespec="$1" \
        || declare -i threshold=$1
      shift ;;
  esac
done

for filename in "$filespec"; do
  # Handle special cases: . and .. (happens when called by a looping script)
  [ "$filename" == '.' -o "$filename" == '..' ] && exit 0

  # Ensure that the file exists and the name contains no wildcards
  [ -f "$filename"] || { LogError "File does not exist: $filename"; exit 1; }

  # Execute via full path to avoid user aliases interfering with output
  declare -r ls_cmd="$(which ls)" 

  declare -i filesize=$($ls_cmd -s "$filename" | cut -d' ' -f1)
  if (( $filesize > $threshold )); then 
    Log "$filename has been preserved because ${filesize}KB > ${threshold}KB"
    exit 0
  else
    Run rm -f $filename
#    Log "$filename is less than ${threshold}KB"
  fi
done
