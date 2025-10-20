#!/bin/bash

source "$DRB_LIB/drbash.sh"

Requires fdupes
declare -r APPNAME='deduper'

PrintHelp() {
  tabs 4
  Log "Performs byte-for-byte file comparisons with interactive results and duplicate file deletion."
  Log
  Log "$(Header "Usage:") $APPNAME [OPTIONS]"
  Log
  Log "$(Header "OPTTIONS:")\tOptional flags"
  Log "\t-h\tDisplay this help screen."
  Log
  Log "$(Header "Notes:")"
  Log "\t* Matching happens in the current directory and recurses through all real subdirectories (symlinks to directories are not followed)."
  Log "\t* In the interactive results screen, type the number of the file you want to keep from the current set and press <enter>."
  Log "\t* Once you have selected the file to keep from every set, press <delete>."
  Log "\t* When the deed is done, type 'exit' and press <enter>."
  Log
}

if [ "$1" ]; then
  PrintHelp
  exit 0
fi

Run fdupes -dr .
