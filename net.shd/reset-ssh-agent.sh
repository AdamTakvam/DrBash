#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/run.sh"

Require openssh-client

if [ "$SSH_AGENT_PID" ]; then
  ssh-agent -k
  if [ "$?" != 0 ]; then
    killall ssh-agent
  fi
fi

# ssh-agent -s outputs a series of variable assignment commands
#   that are then executed by 'eval' to set up the environment.
eval "$(ssh-agent -s)"

for file in ~/.ssh/*; do
  if [ "$(grep PRIVATE "$file")" ]; then
    ssh-add "$file"
  fi
done
