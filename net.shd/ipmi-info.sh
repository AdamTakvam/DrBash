#!/bin/bash

source "${DRB_LIB:-lib}/general.sh"
Require ipmitool

PrintHelp()
{
  echo "IPMI Ping utility connects to the specified IPMI/iDRAC endpoint and displays the sysinfo report."
  echo
  echo "Usage: $(basename $0) IP [username] [password]"
  echo -e "\tIP\t\t[req] IP address of IPMI/iDRAC interface"
  echo -e "\tusername\t[opt] IPMI/iDRAC username [default=root]"
  echo -e "\tpassword\t[opt] Password for <username> [default=calvin]"
  echo
}

ip=$1
username=${2:-'root'}
password=${3:-'calvin'}

[ -z "$ip" ] && { PrintHelp; exit 1; }

ipmitool -I lanplus -H $ip -U $username -P $password delloem sysinfo
