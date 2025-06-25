#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
Require nmap

declare -r APPNAME='nmap'

PrintHelp() {
  echo "Nmap wrapper for preconfigured modes (adapted from ZenMap)."
  echo
  echo "Usage: $APPNAME [OPTS|MODE] [PARAMS] TARGET"
  echo
  echo -e "OPTS\t(optional) Wrapper options"
  echo -e "\t-h\t\tDisplay this help screen"
  echo -e "\t-hh\t\tDisplay the nmap tool's help screen"
  echo
  echo -e "MODE\t(optional) One of the following (either full or short form:"
  echo -e "\tregular, r, -\tThe default mode with no parameters specified. This is the default if no mode is specified to ensure passthrough compatabvility with nmap."
  echo -e "\tquick, q\tQuick scan of only the top 100 most commonly used ports."
  echo -e "\tquick+, q+\tQuick scan plus version and OS detection."
  echo -e "\ttraceroute, tr\tQuick traceroute includes router/hop information."
  echo -e "\tping, p\tPing scan skips the port scanning."
  echo -e "\tintense, i\tIntense scan checks the top 1000 most common ports and attempts version and OS detection."
  echo -e "\tintense+udp, i+udp\tIntense scan plus UDP does everything Intense scan does but adds UDP into the mix."
  echo -e "\tintense+tcp, i+\tIntense scan plus TCP scans all 65,535 ports instead of just the top 1000."
  echo -e "\tintense-ping, i-ping\tIntense scan without ping assumes the host is up."
  echo -e "\tcomprehensive, c\tComprehensive scan throws everything and the kitchen sink at your target(s)."
  echo
  echo -e "PARAMS\t(optional) Any additional parameters you would like to pass to nmap."
  echo -e "TARGET\tHostnames, IP, or IP range to scan. See 'info nmap' for more details."
  echo
}

declare -A PARAMS ABBR
declare -Ar PARAMS=( \
  ["regular"]=" " \
  ["quick"]='-T4 -F' \
  ["quick+"]='-sV -T4 -O -F –version-light' \
  ["traceroute"]='-sn -traceroute' \
  ["ping"]='-sn' \
  ["intense"]='-T4 -A -v' \
  ["intense+udp"]='-sS -sU -T4 -A -v' \
  ["intense+tcp"]='-p 1-65535 -T4 -A -v' \
  ["intense-ping"]='-T4 -A -v -Pn' \
  ["comprehensive"]="-sS -sU -T4 -A -v -PE -PP -PS80,443 -PA3389 -PU40125 -PY -g 53 --script=\"default or (discovery and safe)\"" \
)

declare -Ar ABBR=( \
  ["--"]='regular' \
  ["r"]='regular' \
  ["q"]='quick' \
  ["q+"]='quick+' \
  ["tr"]='traceroute' \
  ["p"]='ping' \
  ["i"]='intense' \
  ["i+udp"]='intense+udp' \
  ["i+"]='intense+tcp' \
  ["i-ping"]='intense-ping' \
  ["c"]='comprehensive')

case "$1" in
  "" | -h | --help | ? | -?)
    PrintHelp
    exit 0 ;;
  -hh)
    /usr/bin/nmap -h
    exit 0 ;;
esac

# Figure out whether $1 is a mode or not.
mode="${ABBR["$1"]:-"$1"}"
params="${PARAMS["$mode"]}"
[ "$params" ] && shift

nmap="${BINPATH:-/usr/bin}/nmap" 
params="$params $@"

echo "$nmap $params"
sudo "$nmap" $params
