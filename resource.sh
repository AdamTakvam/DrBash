#!/bin/bash

Help() {
  echo "Re-sources the specified script. Used when developing new features in core libraries only."
  echo "Important: You must source this script in order for it to do anything useful."
  echo "  Otherwise, you just create a subshell, initialize it, and then destroy it."
  echo "  And that's not very helpful at all, is it? No, it isn't."
  echo
  echo "Usage: source $(basename "$0") SCRIPT_FILE"
  echo
}

[[ -z "$1" || "$1" == -h ]] && { Help; exit 0; }

if [[ ${BASH_SOURCE[0]} == $0 ]]; then
  echo "Error: This script must be sourced in order to not be a pointless waste of time!"
  exit 1
else
  lib="$1"
  mutex="$(echo "$(basename "$lib")" | sed -E 's/(.*).sh/__\1/')"
  unset $mutex
  source "$lib"
fi
