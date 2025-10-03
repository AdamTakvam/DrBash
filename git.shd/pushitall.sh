#!/bin/bash

Help() {
  echo "Adds all untracked changes, then commits pending local code changes, then pushes those changes to 'main'"
  echo "Equivalent to: pushit -a"
  echo
  echo "Usage: $(basename "$0") [-h] [msg]"
  echo
  echo "Parameters:"
  echo -e "\t-h\tPrint this help screen."
  echo -e "\tmsg\tYour commit message [default: Something you probably don't want]"
  echo
}

case "${1-}" in
  -h | --help)
    Help ;;
  "" | *)
    pushit -a "$1" ;;
esac
