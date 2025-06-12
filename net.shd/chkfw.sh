#!/bin/bash

source ${USERLIB:-$HOME/lib}/general.sh

declare -r RUNNING="${COLOR['LGREEN']}Running${COLOR['NONE']}"

# UFW
if [ "$(which ufw)" ]; then
  if [ "$(sudo ufw status | grep inactive)" ]; then
    echo -e "UFW:\t\tStopped"
  else
    echo -e "UFW:\t\t$RUNNING"
  fi
else
  echo -e "UFW:\t\tNot Installed"
fi

# Firewalld
if [ "$(which firewall-cmd)" ]; then
  if [ "$(sudo firewall-cmd --state | grep running)" ]; then
    echo -e "Firewalld:\t$RUNNING"
  else
    echo -e "Firewalld:\tStopped"
  fi
else
  echo -e "Firewalld:\tNot Installed"
fi

# IPTables
if [ "$(which iptables)" ]; then
  if [ "$(sudo iptables -V | grep -E ' \(nf_tables\) *$')" ]; then
    echo -e "IPTables:\tStopped"
  else
    echo -e "IPTables:\t$RUNNING"
  fi
else
  echo -e "IPTables:\tNot Installed"
fi

# NFTables
if [ "$(which nft)" ]; then
  if [ "$(sudo systemctl status nftables | grep active)" ]; then
    echo -e "NFTables:\t$RUNNING"
  else
    echo -e "NFTables:\tStopped"
  fi
else
  echo -e "NFTables:\tNot Installed"
fi
