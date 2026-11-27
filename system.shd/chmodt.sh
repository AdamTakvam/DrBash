#!/bin/bash

printhelp()
{
  echo "Execute chmod on only files or directories below the specified directory recursively."
  echo
  echo "Syntax: chmodt TYPE PERMS [OPTIONS] [PATH...]"
  echo
  echo "Parameters:"
  echo -e "\tTYPE\tf = files, d = directories (same as 'find -type')"
  echo -e "\tPERMS\tSame as you would pass into 'chmod'. All formats accepted (e.g. 644 or o+w)."
  echo -e "\tOPTIONS\t(Optional) Any valid option you would pass to chmod. Pass in \"\" if you want to specify PATH."
  echo -e "\tPATH\t(Optional) One or more directories (everything below them) or directory/pattern"
  echo -e "\t\t(e.g. \"/data/*.mp4\"; the pattern is matched against names, ignoring case). Default=\$PWD"
  echo
  echo "Directories also get the setgid bit (see below)."
  echo
}

if [ ! "$2" ]; then
  printhelp
  exit 1
fi

nodetype="$1"
perms="$2"
opts="$3"
shift $(( $# < 3 ? $# : 3 ))
declare -a paths=("$@")
(( ${#paths[@]} )) || paths=("$PWD")

case "$nodetype" in
  f | d) ;;
  *) echo "chmodt: TYPE must be f (files) or d (directories), not: $nodetype" >&2; exit 1 ;;
esac

declare -a optArr
read -ra optArr <<< "$opts"   # OPTIONS may hold more than one option

declare -i retval=0
for path in "${paths[@]}"; do
  if [ -d "$path" ]; then
    basedir="$path"
    name="*"
  else
    basedir="$(dirname "$path")"
    name="$(basename "$path")"
  fi

  if [ ! -d "$basedir" ]; then
    echo "chmodt: Not a directory: $basedir" >&2
    retval=1
    continue
  fi

  # + instead of \; hands chmod as many names as fit, instead of running sudo once per file
  find "$basedir" -type "$nodetype" -iname "$name" -exec sudo chmod "${optArr[@]}" "$perms" {} + || retval=1

  # Add setgid bit on directories
  # It ensures that any files created in the directory inherit the group membership of the parent directory.
  # I can't imagine a scenario where you would not want this to be the behavior, so it's not optional.
  if [ "$nodetype" == 'd' ]; then
    find "$basedir" -type d -iname "$name" -exec sudo chmod "${optArr[@]}" g+s {} + || retval=1
  fi
done

exit $retval
