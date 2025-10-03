#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/general.sh"

RequiresPy() {
  pkg="$1"
  [ -z "$pkg" ] && return 0

  installed="$(pip list | grep "$pkg")"
  if [ -z "$installed" ]; then
    pip install "$pkg"
  fi
}

Requires cpulimit
Requires ffmpeg
RequiresPy "jellyfish"

cpulimit -l 60 -- $PWD/media-dedupe.py -r --audio
