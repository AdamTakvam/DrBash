#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
Requires findutils

declare -r APPNAME="find2"

PrintHelp() {
  tabs 4
  echo "Help!"
}

if [ -z "$1" ] || [ "$1" == "?" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  PrintHelp
  exit
fi

# Path param is special
declare -r path="$1"
shift

if [ ! -e "$path" ]; then
  LogError "Path $path does not exist!"
  exit 2
fi

declare -A findParams=(['path'] "$path")
declare -i unsupCount=0

while "1"; do
  case "$1" in
    -maxdepth)
      findParams+=(['maxdepth'] "$2")
      shift; shift
      ;;
    -prune)
      findParams+=(['maxdepth'] 1)
      shift
      ;;
    *) # Unsupported parameter (passthrough)
      parm="$1"
      [ "$2" == "-*" ] || { parm+=" $2"; shift; }
      findParams+=(["unsup$unsupCount"] "$parm")
      (( unsupCount++ ))
      shift
      ;;
  esac
done


Run find
