#!/bin/bash

if [ "$1" ]; then
  export PS4='${BASH_SOURCE[0]}:$LINENO '
  bash -x $@
else
  echo "Error: No script name specified"
fi
