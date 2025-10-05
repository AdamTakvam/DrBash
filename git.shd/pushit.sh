#!/bin/bash

Help() {
  echo "Commits pending local code changes then pushes those changes to 'main'"
  echo
  echo "Usage: $(basename "$0") [-a|-h] [msg]"
  echo
  echo "Parameters:"
  echo -e "\t-a\tAdd all untracked changes before committing."
  echo -e "\t-h\tPrint this help screen."
  echo -e "\tmsg\tYour commit message [default: Something you probably don't want]"
  echo
}

Commit() {
  if [[ -x ./_precheck.sh ]]; then
    if ! ./_precheck.sh; then
      read -n1 -p "Are you sure you still want to proceed with the checkin [y/N]?" choice; echo
      [[ ${choice,,} == 'y' ]] || exit
    fi
  fi

  cMsg="${1:-I have modified the code. Pray that I don\'t modify it further!}"
  git commit -m "$cMsg" && git push
}

case "$1" in
  -h | --help)
    Help ;;
  -a)
    git add .
    Commit "$2" ;;
  "" | *)
    Commit "$1" ;;
esac

