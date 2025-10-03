#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/logging.sh"

Help() {
  Log "Usage: mvx 'srcglob' 'destpattern'"
  Log "Example: mvx '*.jpeg' '*.jpg'"
}

Rename() {
  local srcglob="$1"
  local dstpattern="$2"

  shopt -s nullglob

  for src in $srcglob; do
    local base="${src##*/}"
    local name ext newname

    # Extract filename and extension
    name="${base%.*}"
    ext="${base##*.}"

    # Build new filename
    newname="${dstpattern//\*/$name}"

    if [[ "$src" == "$newname" ]]; then
      echo "Skipping $src (identical name)"
    else
      echo "mv -- '$src' '$newname'"
      mv -- "$src" "$newname"
    fi
  done
}

[[ "${1,,}" == -h ]] && { Help; exit 0; }
[[ $# -ne 2 ]] && { Help >&2; exit 1; }

