#!/bin/bash

source ${USERLIB:-$HOME/lib}/general.sh
Require "network-manager"

PrintHelp() {
  echo "Sets a static IP address on the indicated interface."
  echo
  echo "Usage: $(basename $0) [-v] IF IP[/MASK] [GW] [DNS]"
  echo
  echo -e "-v\tVerbose output"
  echo -e "-vv\tDebug output"
  echo -e "IF\tThe name of the interface (according to "ip addr")"
  echo -e "IP\tThe IPv4 address you want to set or "auto" for dhcp."
  echo -e "MASK\t(optional) The subnet mask for the new address (default: 24)"
  echo -e "GW\t(optional) The gateway address (either full IP or just the last octet) (default: 1)"
  echo -e "DNS\t(optional) The address of the DNS server (default: gateway address)"
}

# Deletes all local routes associated with the specified interface from the route table
# Local routes = no gateway specified. (i.e. subnets within the local broadcast domain)
# $if = Interface name
DeleteLocalRoutes() {
  [ -z "$if" ] && { echo "Internal Error: DeleteLocalRoutes() called with no \$if defined."; return 1; }
  LogDebug "DeleteRoutes($if)"

  local _routes
  IFS=$'\n' _routes=(`route | grep $if`)
  LogDebug "Found ${#_routes[*]} existing routes on this interface."

  local _route
  for _route in ${_routes[*]}; do
    LogDebug "Examining route: $_route"

    local _routeBits
    IFS=' ' _routeBits=($_route)
    local _dest=${_routeBits[0]}
    local _gw=${_routeBits[1]}
    local _mask=${_routeBits[2]}

    [ "$_gw" != "0.0.0.0" ] && continue

    LogTee "Deleting route: $_route"

    if [ "$_dest" == "default" ]; then
      # dest is "default"
      Run route del default dev $if
    elif [ "$(echo "$_dest" | grep "\.0$")" ]; then
      # dest is a network
      Run route del -net "$_dest" netmask "$_mask" dev $if
    else
      # dest is a host
      Run route del -host "$_dest" dev $if
    fi
  done
}

# Deletes all connections with the specified name.
#   Yes, there can be more than one connection with the same name.
# $connName = The connection name
DeleteConnections() {
  [ -z "$connName" ] && { echo "Internal Error: DeleteConnections() called with no \$connName defined"; exit 1; }
  LogDebug "DeleteConnections($connName)"

  local _conns
  IFS=$'\n' _conns=(`nmcli conn | grep $connName`)
  LogDebug "Found ${#_conns[*]} existing connections."

  local _conn
  for _conn in ${_conns[*]}; do
    LogTee "Deleting connection: $_conn"
    
    local _connBits
    IFS=' ' _connBits=($_conn)
    local _uuid="${_connBits[1]}"
    
    Run nmcli conn delete uuid $_uuid
  done
}

# Configures the specified interface to use DHCP, if requested
# $if = The interface name
# $connName = The connection name
ConfigureDHCP() {
  LogTee "Configuring interface $if to use DHCP..."
  DeleteConnections "$connName"
  DeleteLocalRoutes "$if"
  Run nmcli dev mod "$if" ipv4.method auto ipv6.method disabled
  LogTee "Device configured. Querying for address information..."
  Run dhclient "$if"
  if [ $? == 0 ]; then
    LogTee "Device address information obtained!"
    ip addr show dev "$if" | LogTee
  else
    LogTee "Failed to obtain address information!"
    return 2
  fi
  return 0
}

# Configures the specified interface to use the specified IP address
# $if = The interface name
# $connName = The connection name
# $ip = The desired IP address
# $mask = The subnet mask (expresed in CIDR notation)
# $gw = The default gateway
# $dns = The primary DNS server
ConfigureStatic() {
  Run nmcli dev mod "$if" ipv4.method manual ipv4.addresses "$ip/$mask" ipv4.gateway "$gw" ipv4.dns "$dns" ipv6.method disabled

  DeleteConnections "$connName"

# A new connection will be creating using device defaults (above) when the interface is brought up
#  Run nmcli conn add con-name "$connName" ifname "$if" type ethernet ip4 "$ip/$mask" gw4 "$gw"
#  Run nmcli conn mod "$connName" ipv4.dns "$dns"

  DeleteLocalRoutes "$if"

# This should also be handled automatically, but no harm in doing it yourself, I suppose.
  Run route add -net "$net/$mask" dev "$if"

  Run nmcli con up "$connName"

  LogTee "New connection $connName up on interface $if"
  LogTee "IP/Subnet = $ip/$mask"
  LogTee "Gateway = $gw"
  LogTee "DNS = $dns"
}

if [[ "$1" =~ ^-v ]]; then
  declare -rg VERBOSE=1
  [ "$1" == "-vv" ] && declare -rg DEBUG=1
  shift
fi

[ -z "$2" ] && { PrintHelp; exit 1; }

LogDebug "Running in debug mode. No changes will be made to the system."

IFS='/' ipBits=($2)

declare -rg if="$1"
LogDebug "if=$if"

declare -rg ip="${ipBits[0]}"
LogDebug "ip=$ip"

declare -rg connName="$if-static"
LogDebug "connName=$connName"

# Shortcut the rest of the logic if we're doing DHCP
if [ "${ip,,}" == "auto" ] || [ "${ip,,}" == "dhcp" ]; then
  ConfigureDHCP
  exit 0
fi

declare -r net="`echo "$ip" | cut -d. -f-3`.0"
LogDebug "net=$net"

declare -r mask="${ipBits[1]:-24}"
LogDebug "mask=$mask"

gw="${3:-1}"
LogDebug "gw=$gw"

dns="$4"
LogDebug "dns=$dns"

# Figure out the gateway address
(( "${#gw}" < 4 )) && { gw="$(echo "$ip" | cut -d. -f-3).$gw"; LogDebug "gw=$gw"; }

# DNS defaults to gateway
[ -z "$dns" ] && { dns="$gw"; LogDebug "dns=$dns"; }

ConfigureStatic
