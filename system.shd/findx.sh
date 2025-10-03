#!/bin/bash

declare -r APPNAME='findx'

Help() {
  Log "Drop in replacement for `find` that runs any `-exec` parameters the way you expect them to!"
  Log
  Log "$(Header "Usage:") $APPNAME <same as `find` command>"
  Log
  Log "Recommended usage: Add 'alias find=findx' to your ~/.bashrc file and enjoy not goinmg prematurely bald."
  Log "Bonus: You can now specify {} multiple times wherever you want!"
  Log
}

findCmd="$(printf "%s" "$*" | sed -E 's/^(.*)-exec/\1/')"
execCmd="$(printf "%s" "$*" | sed -E 's/-exec(.*)$/\1/')"

if [ "$execCmd" ]; then
  execCmd="$(printf "%s" "$*" | sed -E "s/('\{\}'|\"\{\}\"|\{\})/\"\$f\"/g")"     # We take no prisoners!

  while IFS= read -r -d '' f; do
    "$execCmd"
  done < <(find $findCmd -print0)
else
  find "$findCmd"
fi
