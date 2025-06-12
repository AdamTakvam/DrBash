#!/bin/bash

printhelp()
{
  echo "Execute chmod on only files or directories below the specified directory recursively."
  echo
  echo "Syntax: chmodt TYPE PERMS [PATH] [OPTIONS]"
  echo
  echo "Parameters:"
  echo -e "\tTYPE\tf = files, d = directories (same as 'find -type')"
  echo -e "\tPERMS\tSame as you would pass into 'chmod'. All formats accepted
  (e.g. 0644 or +w)."
  echo -e "\tPATH\t(Optional) Limit affected files by path & glob pattern." 
  echo -e "\tOPTIONS\t(Optional) Any valid option you would pass to chmod."
  echo ""
}

if [ ! "$2" ]; then
  printhelp
  exit 1
fi

nodetype="$1"
perms="$2"
opts="$4"

basedir="."
name="*"
if [ "$3" ]; then
  basedir="$(dirname "$3")"
  name="$(basename "$3")"
fi

find "$basedir/" -type $nodetype -iname "$name" -exec sudo chmod $opts $perms "{}" \;
