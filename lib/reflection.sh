# vim: filetype=bash

[[ -n $__reflection ]] && return 0
declare -g __reflection=1

# Reflection functions to interrogate your own scripts
# Why? To implement dynamic programming paradigms.
# If that makes your head hurt, just close this file and step away. 
#   It'll still be here when you're ready.

IsArray() {
  if [[ "$1" ]] && [[ "$(declare -p "$1" 2>/dev/null)" =~ -a ]]; then
    return 0
  else
    return 1
  fi
}

IsDict() {
  if [[ "$1" ]] && [[ "$(declare -p "$1" 2>/dev/null)" =~ -A ]]; then
    return 0
  else
    return 1
  fi
}

IsInt() {
  if [[ "$1" ]] && [[ "$(declare -p "$1" 2>/dev/null)" =~ -i ]]; then
    return 0
  else
    return 1
  fi
}

IsReadOnly() {
  if [[ "$1" ]] && [[ "$(declare -p "$1" 2>/dev/null)" =~ -r ]]; then
    return 0
  else
    return 1
  fi
}

# Writes the specified in-memory function to a file so that it can be run via exec, etc.
# + $1 = The name of the function.
# - stdout = The new filename containing the function definition.
SaveFunction() {
  local funcName="$1"
  [[ -z "$funcName" ]] && return 99
  funcImpl="$(type -a "$funcName")"
  if [[ "$funcImpl" =~ not\ found ]]; then
    return 1
  else
    # We want all but the first line written to the outFile
    local outFile="/tmp/$funcName"
    echo "$funcImpl" | tail -n +2 > "$outFile"
    printf "$outFile"
  fi
}

# Gets functions preceded by the specified function attribute
# + $1 = The name of the function attribute. Should begin with #@
# + $2 = The name of an array to hold the function names
# - retVal = success/fail
GetReflectedFunctions() {
  [[ -z "$1" ]] || [[ -z "$2" ]] && return 99

  local attr_name="$1"
  local -n _results="$2"
  local caller_script="${BASH_SOURCE[1]}"

  [[ ! -r "$caller_script" ]] && {
    echo "Error: Cannot read caller script: $caller_script" >&2
    return 1
  }

  local prev_line line fname

  while IFS= read -r line; do
    # Detect function line
    if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then
      fname="${BASH_REMATCH[1]}"
      [[ "$prev_line" == "$attr_name" ]] && _results+=("$fname")
    fi
    prev_line="$line"
  done < "$caller_script"
}

# Example Usage:
#
# #!/usr/bin/env bash
# source "$DRB_LIB/reflection.sh"
#
# #@reflect
# do_alpha() { echo "alpha"; }
#
# do_ignore() { echo "you shouldn't see this"; }
#
# #@reflect
# do_bravo() { echo "bravo"; }
#
# declare -a found
# GetReflectedFunctions found
#
# Log "Matched:"
# Log -l "${found[@]}"
#
# Log "Executing:"
# for fn in "${found[@]}"; do
#  "$fn"
# done

