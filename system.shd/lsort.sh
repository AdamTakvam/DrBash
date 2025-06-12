#!/bin/bash

printHelp () {
  echo "Prints a list of all of the immediate subdirectories of the specified parent
  directory in order according to the number of child elements they contain."
  echo
  echo "Usage: $0 [DIR]"
  echo
  echo "Parameters:"
  echo -e "  DIR\t(optional) The directory to scan (default = CWD)"
}

[[ "${1,,}" =~ ^-h ]] && printHelp && exit 1

scanDir="${1:-.}"
dirSort=()

for dir in $scanDir/*
do
  if [ -d "$dir" ]; then
    numFiles=$(ls -1 "$dir/" | wc -l)
    # echo "dirSort += $numFiles~$dir"
    dirSort+=("$numFiles~$dir"$'\n')
  fi
done

# echo "dirSort = ${dirSort[*]}"

# Sort the directory array by number of elements
IFS=$'\n' 
for numDir in $(sort -rn <<<${dirSort[*]})
do
  # echo "numDir = $numDir"
  IFS='~' read -r numFiles dir <<< "$numDir"
  echo -e "$numFiles\t$dir"
done
