#!/bin/bash

TestCommandX() {
  if (( $# == 3 )); then
    return 0;
  else
    echo "Failed to call TestCommandX with correct parameters"
    echo "Parameters: $@"
    return 1
  fi
}
export -f TestCommandX

source ~/lib/lib/general.sh

TestRun1() {
  [ `Run TestCommandX a b c` ] || failed=1
  [ `Run TestCommandX "a sp b" "d sp e" f` ] || failed=1
}

export VERBOSE=1

TestRun1
