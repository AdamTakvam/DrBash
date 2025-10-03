#!/usr/bin/env bash
set -o pipefail

: "${DRB_LIB:?Edit your ~/.bashrc file and add: export DRB_LIB=/usr/local/lib/drbash}"
source "$DRB_LIB/drbash.sh"

Help() { 
  LogHeader "hello-drbash"
  Log "Says hello with deps + logging."
}

case "${1-}" in -h | --help) Help; exit 0 ;; esac

Require cowsay

out="$(Run -u cowsay 'Hello, DrBash!')" || exit $?
LogHeader "Output:"
Log "$out"
