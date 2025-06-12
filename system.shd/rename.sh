#!/bin/bash

declare -r APPNAME="rename"

HelpSummary() {
  echo "Bulk moves/renames files based on regex matching and substring substitution."
}

HelpUsage() {
  echo "Usage: $APPNAME <match-pattern> <replacement>"
}

HelpParameters() {
  echo "match-pattern"
  echo -e "\tAn extended regular expression, not a glob. Know the difference!"
  echo -e "\tOnly files where some substring of the name matches this expression will be renanmed. Like grep."
  echo "replacement"
  echo -e "\tThe text that the matching substring should become. Supports backreferences. Like sed -E."
}

HelpExamples() {
  echo -e "Example 1:\tRename all files with .data extension to .txt"
  echo -e "\tFiles:\tcmd.data stuff.data"
  echo -e "\tCommand:\t$APPNAME .data .txt"
  echo -e "\tResult:\tcmsd.txt stuff.txt"
  echo
  echo -e "Example 2:\tRename 
}

PrintHelp()
{
  echo
  HelpSummary
  echo
  HelpUsage
  echo
  HelpParameters
  echo
  HelpExamples
}
