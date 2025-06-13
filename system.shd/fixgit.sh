#!/bin/bash

source "${USERLIB:-$HOME/lib}/run.sh"

Require openssh-client

if [ "$SSH_AGENT_PID" ]; then
  ssh-agent -k
  if [ "$?" != 0 ]; then
    killall ssh-agent
  fi
fi

eval `ssh-agent -s`

for file in ~/.ssh/*; do
  if [ "$(grep PRIVATE "$file")" ]; then
    ssh-add "$file"
  fi
done
