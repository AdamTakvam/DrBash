#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/dr_bash.sh"
declare -r APPNAME='hardtabs'

Help() {
  tabs 4
  Log "Converts tab (0x09) characters to spaces."
  Log
  LogTable "$(Header "Usage:")\t$APPNAME COMMAND [OPTIONS] [FILE]"
  Log "\t$APPNAME -h"
  Log
  LogHeader "COMMAND"
  LogTable "\tlist\tShow all lines that contain tabs.
  \treplace\tReplace all tabs with spaces."
  Log
  LogHeader "OPTIONS"
  LogTable "\t<default>\tIf no options are specified, COMMAND will operate on all files in the current directory and all subdirectories, recusively.
  \t-r\tRecurse subdirectories (default)
  \t-R\tDo not recurse subdirectories
  \t-s#\tNumber of spaces to insert in place of each tab character (default=4)
  \t--\tOperate on data piped to stdin (do not specify anything after this)"
  Log
  LogHeader "FILE"
  LogTable "\tFile\tThe name of a file or glob pattern to operate on (use either no quotes or double quotes for globs NO single-quotes!)
  \tPath\tA path to use instead of the current directory to operate on."
  Log
  Log "$(ColorText YELLOW "Warning:") If you specify a glob and it matches both files and directories, they will be operated on according to what they are."
  Log "         So if you run $APPNAME replace ~/*.txt"
  Log "         and you have a file called ~/diary.txt and a directory called ~/allmytext.txt,"
  Log "         $APPNAME is going to work on ~/diary.txt and $(Bold "every") file located under ~/allmytext.txt and every subdirectory,"
  Log "         not just the files matching *.txt!"
  Log
  Log "FAQ: How can I make $APPNAME operate on just the files matching *.txt in an entire directory tree?"
  Log "Answer: Something like this: find . -name "*.txt" -exec $APPNAME replace '{}' \;"
  Log
}

# $1 = Recurse subdirerctories [ 0=no, 1=yes]
# $2 Path
FindTabs() {
  [ -z "$2" ] && return 99

  local -ir _recurse="$1"
  local -r _path="$2"



  if [ "$_recurse" ]; then
    find "$_path" -name 
  grep -rPI '\t' '{}' \;
}

ReplaceTabs() {
  vim -n -u NONE -c 'set expandtab tabstop=2 shiftwidth=2 softtabstop=2 | silent! retab | wq'
}
