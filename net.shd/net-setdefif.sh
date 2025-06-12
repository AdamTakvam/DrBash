#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
source "${USERLIB:-$HOME/lib}/net.sh"
declare -r APPNAME="net-setdefif"

PrintHelp() {
  tabs 4
  Log "Configures the specified interface to be the default used for internet access. 
  Note: This script does not configure an unconfigured interface."
  Log
  Log "$(Header "Usage:") $APPNAME [OPTS] IFACE"
  Log
  Log "$(Header "OPTS")\tOptional Flags"
  LogTable "\t-h\tShow this help screen
  $(LogParamsHelp)
  \t-r=<ip|host>\tOverride guessing the gateway address 
  \t\tand use the specified IP address or hostname.
  \t\tNote: When specifying a hostname, make sure that the hostname is
  \t\tresolvable using only the local system \"hosts\" file.
  \t\tNo spaces around the equals sign!"
  Log
  Log "$(Header "IFACE")\tThe name of an interface that can reach the internet."
  Log
  LogHeader "Assumptions:"
  Log "\t* Interface IP is on a /24 subnet."
  Log "\t* Gateway is assigned xxx.xxx.xxx.1 address."
  Log
}

IsDefault() {
  local iface="$1"
  local gwAddr="$2"
  [ -z "$iface" ] && return 1

  if [ "$(ip route get 1.1.1.1 | grep "$iface ${gwAddr:+via $gwAddr}")" ]; then
    echo "$iface is the default interface."
    return 0
  else
    return 1
  fi
}

DeviceExists() {
  local iface="$1"
  [ -z "$iface" ] && return 1

  # The following command will generate multiline output
  #   regarding the properties of the interface
  #   or it will print one line about the device not existing
  if (( $(ip addr show dev "$iface" | wc -l) > 1 )); then
    echo "$iface exists!"
    return 0
  else
    return 1
  fi
}

DeleteDefaultRoutes() {
  local FNAME="DeleteDefaultRoutes()"
  local -i numDefault=$(route | grep '^0.0.0.0' | wc -l)
  local -i iter=1

  while [ "$(route | grep '^0.0.0.0')" ]; do
    
    Run -r route -v del 0.0.0.0
    
    LogVerbose -n "$(( iter++ ))"
    if [ $iter -gt $numDefault ]; then
      LogError "\n$FNAME has failed to delete the existing routes."
      return 1
    fi
  done
  
  echo -n '|'

  local -i numDefault=$(route | grep '^default' | wc -l)
  iter=1
  while [ "$(route | grep "^default")" ]; do
    
    Run -r route -v del default
    
    LogVerbose -n "$(( iter++ ))"
    if [ $iter -gt $numDefault ]; then
      LogError "\n$FNAME has failed to delete the existing routes."
      return 1
    fi
  done

  echo
}

for param in "$@"; do
  case "$param" in
    "" | -h | --help) 
      PrintHelp
      exit 0 ;;
    -r*)
      gwAddr="$(echo "$param" | cut -d'=' -f2)" ;;
    -*)
      continue ;;
    *)
      if [ "$iface" ]; then
        LogError "You may not specify the interface name parameter more than once."
        exit 1
      else
        declare iface="$param" 
      fi ;;
  esac
done

if [ ! CanSudo ]; then
  LogErrorTee "$APPNAME: This command requires elevated permissions that user ($(whoami)) does not possess."
  exit 1
fi

if [ ! "$(DeviceExists $iface)" ]; then
  LogError "Device $iface does not exist!"
  exit 1
fi

if [ "$(IsDefault $iface $gwAddr)" ]; then
  LogError "Interface $iface appears to already be the default."
else
  # Get probable gateway address for specified interface
  [ "$gwAddr" ] || gwAddr="$(ip addr show dev $iface | grep inet | awk '{ print $2 }' | awk -F. '{ print $1"."$2"."$3".1" }')"
  
  if [ ! "$gwAddr" ]; then
    LogError "Error: $iface doesn't appear to have an address!"
    LogError "$(ip addr show dev $iface)"
    exit 1
  fi

  Log "Deleting existing default routes..."
  DeleteDefaultRoutes

  if [ $? == 0 ]; then
    Log "Adding default route for $iface..."
    Run -r ip route add default dev $iface gw $gwAddr metric 0
  fi
fi

Log "$(route)"
