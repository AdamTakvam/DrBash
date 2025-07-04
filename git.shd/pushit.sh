#!/bin/bash

Commit() {
  cMsg="${1:-Changed code}"
  git commit -m "$cMsg" \
    && git push
}

case "$1" in
  -a)
    git add .
    Commit "$2" ;;
  "" | *)
    Commit "$1" ;;
esac

