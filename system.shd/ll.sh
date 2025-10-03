#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/arrays.sh"

declare -a passFlags=('-l')
declare -a passPaths=()
declare -i longList=0

for p in "$@"; do
  case "$p" in
    -*)
      passFlags+=("$p") ;;
    *)
      # If the last character in a given path is not a /
      #   then append a -d flag so it will give us the directory properties.
      # If it does end in a / don't do anything 
      #   and it will display the properties of the contents of the directory.
      # If there was no trailing / and the path points to a symlink,
      #   resolve the symlink and display the properties of the target directory.
      if [ "${p: -1}" != '/' ]; then
        passFlags+=('-d')
        if [[ -L "$p" ]]; then
          passPaths+=("$(realpath "$p")")
        else
          passPaths+=("$p")
        fi
      else
        passPaths+=("$p") 
      fi ;;
  esac
done

exe="ls $(SerializeArray passFlags) $(SerializeArray -q passPaths)"
eval "$exe"


