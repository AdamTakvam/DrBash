#!/bin/bash
export PS4='${BASH_SOURCE[0]}:$LINENO '

scriptName="$1"

if [[ "$scriptName" ]]; then
  if [[ "$(type -t "$scriptName")" == "file" ]]; then
    bash -x "$@"
  else
    file='debug_temp.sh'
    printf "%s\n" '#!/bin/bash' > "$file"
    printf "%s" "$@" >> "$file"
    bash -x "$file"
    rm "$file"
  fi
else
  echo "Error: No script name specified"
fi
