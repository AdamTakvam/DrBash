#!/bin/bash

source "${DRB_LIB:-/user/local/lib}/logging.sh"

declare -r APPNAME=vish

Help() {
  tabs 4
  Log "Edits a script by just specifying its executable name."
  Log
  Log "$(Header "Usage:") $APPNAME EXE_NAME"
  Log
  LogTable "EXE_NAME\tThe name of any executable script.
  \tDoes not support: 
  \t\t- Compiled commands
  \t\t- Shell builtins
  \t\t- Shell keywords
  \t\t- Aliases
  \t\t- Functions"
  Log
}

if [[ -z "$1" ]] || [[ "${1,,}" == '-h' ]]; then
  Help
  return 0
fi

declare -r cmd="$1"

cmdType="$(type -f "$cmd")"
if [[ "$cmdType" == 'file' ]]; then
  path="$(realpath "$(type -P "$cmd")")"

  if IsDebugEnabled; then
    read -n1 -p "Do you want to edit $path [Y/n]? " choice; echo
    [[ "${choice,,} == 'n' ]] && exit 0
  fi
  
  ${EDITOR:-vim} "$path" 
else
  LogError "$cmd is a $cmdType, which is not supported"
  return 1
fi
