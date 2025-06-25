#!/bin/bash

source ~/lib/modules/general.sh
source ~/lib/modules/net.sh

printHelp () {
  echo "Help!"
}

if [ ! hasSudo ]; then
  echo "You do not have sufficient privileges to run this script."
  echo "(Editing this script to remove this message will not cause you to
  suddenly have the necessary privileges.)"
  exit 1
fi

# Initialize interfaces array
declare -a interfaces
getIfArray
#echo "Interfaces: ${interfaces[*]}"

for net in ${interfaces[*]}; do
  echo "Flushing: $net"
  sudo ip addr flush $net
done

echo "Restarting: networking.service..."
sudo systemctl restart networking

dhcp="no"
[ "$(grep dhcp /etc/network/interfaces)" ] && dhcp="yes"
[ "$(grep dhcp /etc/network/interfaces.d/*)" ] && dhcp="yes"
if [ "$dhcp" == "yes" ]; then
  echo "Initializing dynamic interfaces via DHCP..."
  sudo dhclient
fi

# Print the result
ip addr
