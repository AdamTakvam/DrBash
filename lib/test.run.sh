#!/bin/bash

source "${DRB_LIB:-.}/run.sh"

TestCommandX() {
  if (( $# == 3 )); then
    return 0;
  else
    echo "Failed to call TestCommandX with correct parameters"
    echo "Parameters: $@"
    return 1
  fi
}

LogEnableVerbose

# TestRun1() {
  retval=0

  Run -u TestCommandX a b c 
  [ "$?" == 0 ] || retval=1
  
  Run -u TestCommandX "a sp b" "d sp e" f 
  [ "$?" == 0 ] || retval=1

#  return $retval
# }

# LogEnableVerbose

# TestRun1
# exit $?
exit $retval
