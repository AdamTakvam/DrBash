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
  echo -e "\tOPTIONS\t(Optional) Any valid option you would pass to chmod. Pass in "" if you want to specify PATH."
  echo -e "\tPATH\t(Optional) Limit affected files by one or more paths & glob patterns. Default=\$PWD/*" 
  echo ""
}

if [ ! "$2" ]; then
  printhelp
  exit 1
fi

nodetype="$1"; shift
perms="$1"; shift
opts="$1"; shift
declare -a paths=("$@")

basedir="$PWD"
name="*"

if [[ "${#path[@]}" ]]; then
  [[ "$path" =~ ^".*"$ ]] && path='"$path"'
  basedir="$(dirname "$path")"
  basedir="${basedir:-$PWD}"
  name="$(basename "$path")"
  name="${name:-*}"
fi

# Add setgid bit on directories
# It ensures that any files cresated in the directory inherit the group membership of the parent directory.
# I can't imagine a scenario where you would not want this to be the behavior, so it's not optional.
[ "$nodetype" == 'd' ] && perms=$(( 2 & $perms ))

find "$basedir/" -type $nodetype -iname "$name" -exec sudo chmod $opts $perms "{}" \;
