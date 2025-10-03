#!/bin/bash

# WORK IN PROGRESS

Help() {
  echo "Generates global include files. For use by Dr Bash developers only."
  echo
}

shit() {
dir="${1:-lib}"
[[ "${dir::1}" != / ]] && dir="$DRB_SRC/$dir"

globincl="# Auto-generated universal source file.\n"

for s in "$dir"/*.sh; do
  globincl="source \"$s\"\n"
done

libname="$(basename "$dir")"
libname="$(echo "$libname" | sed 's/[.]{0,1}lib//')"
libname="${libname:+-$libname}
printf "%b" "$globincl" > "$dir/drbash$libname.sh
}

test() {
  source "$DRB_LIB/drbash.sh"
  source libgen2.sh
  IsSourced && echo "Sourced" || echo "Not Sourced"
  echo
  printf "\$0 = %s\n" "$0"
  printf "BASH_SOURCE=%s\n" "${BASH_SOURCE[@]}"
}

test
