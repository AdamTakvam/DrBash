#!/bin/bash

source "${USERLIB:-$HOME/lib}/run.sh"

APPNAME='superwhich'

Help() {
  tabs 4
  Log "This is a more aggressive version of 'which' or 'type -a'. Use this before you resort to 'find'"
  Log
  Log "$(Header "Usage:") $APPNAME [Flags] EXE"
  Log
  LogHeader "Flags:"
  LogTable "\t-h\tPriont this help screen.
  $(LogParamsHelp)"
  Log
  Log "$(Header "EXE")\tAn executable program file name."
  Log
  Log "You might want tpo make an alias for this command. If so, toss something like the following in your .bashrc or .zshrc file:"
  Log "\talias sw='superwhich'"
  Log
}

declare exe

ParseCLI() {
  for p in "$@"; do
    case "$p" in
      "" | -h*)
        Help
        exit 0 ;;
      -*)
        ;;  #nothing
      *)
        if [ -z "$exe" ]; then
          exe=$p
        else
          LogError "Error: Only one executable can be specified at a time. 
          [ Be sure you REALLY know what you're doing if you pass a glob into this command. ]"
          exit 2
        fi ;;
    esac
  done
}

ParseCLI "$@"

_Run_FindCmd "$exe"

[ "$?" == 0 ] || LogError "Error Code: $?"
