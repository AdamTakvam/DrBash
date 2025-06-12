#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"

# Environment Variables
: ${LOGROOT:="/var/log"}
: ${HOSTNAME:=`hostname`}
: ${PLEX_HOME:="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/"}

# Constants
declare -r APPNAME="showlog"
declare -r LOGROOT="/var/log"

PrintHelp() {
  tabs 4
  echo "Displays the log for the indicated service. Some known services will display accurate results. For all others, the script makes reasonable guesses to find the logs."
  echo
  echo "Usage: $APPNAME [FLAGS] SERVICE"
  echo
  echo "FLAGS:"
  echo -e "\t-h\t\tDisplay this help screen."
  echo -e "\t-s\t\tAlso display service status (not applicable in all cases)"
  echo -e "\t-n #\tNumber of most recent log message to display (default: 40)"
  echo -e "\t-v\t\tVerbose output"
  echo -e "\t-vv\t\tDebug mode"
  echo -e "SERVICE\t\tThe name of a service (aka \"unit\")"
  echo
  echo "Supported Services:"
  echo -e "\tsystem\t\tKernel service"
  echo -e "\tapt\t\t\tSoftware installation"
  echo -e "\tplex\t\tPlex media server"
  echo -e "\tsamba\t\tWindows interop service"
  echo -e "\tnet\t\tLinux networking subsystem"
  echo -e "\tiperf\t\tPerformance benchmarking tool"
  echo -e "\t*\t\t\tAnything else will be attemped on a best-effort basis"
  echo
  echo "Environment Variables:"
  echo -e "\tLOGROOT\tThe location of your log files (default: /var/logs)"
  echo -e "\tHOSTNAME\tThe name of this computer (if unset, we'll get it another way. Don't sweat it.)"
  echo -e "\tPLEX_HOME\tThe location of the Plex Media Server data directoty (default: /var/lib/plexmediaserver/Library/Application Support/Plex Media Server/"
  echo
}

declare -a logFiles=() svcs=()
declare svcName="" numLines=40

while [ "$1" ]; do
  case "$1" in
    "" | -h | ?)
      PrintHelp
      exit 0 ;;
    -s)
      svcStats=1
      shift ;;
    -n)
      numLines=$2
      shift 2 ;;
    -v)
      LogEnableVerbose
      shift ;;
    -vv)
      LogEnableDebug
      shift ;;
    *)
      svcName="$1"
      shift ;;
  esac
done

[ ! "$svcName" ] && { PrintHelp; exit 1; }

# Prepare service-specific metadata
case "${svcName,,}" in
  sys|system)
    logFiles+=("$LOGROOT/syslog")
    logFiles+=("$LOGROOT/kern.log")
    logFiles+=("$LOGROOT/boot.log") 
    ;;
  apt)
    logFiles+=("$LOGROOT/apt/history.log")
    logFiles+=("$LOGROOT/dpkg.log")
    logFiles+=("$LOGROOT/aptitude.log") 
    ;;
  plex)
    svcs+=("plexmediaserver")
    IFS=$'\n' logFiles+=($(ls -1 "${PLEX_HOME}/Logs/" | grep -Ev "\.[0-9]\.log|\.old\.log"))
    ;;
  samba)
    svcs+=("smbd")
    svcs+=("nmbd")
    logFiles+=("$LOGROOT/samba/log.smbd")
    logFiles+=("$LOGROOT/samba/log.nmbd")
    logFiles+=("$LOGROOT/samba/log.${HOSTNAME^^}") 
    ;;
  net|network|networking)
    svcs+=("networking")
    svcs+=("NetworkManager")
    logFiles+=("$LOGROOT/kern.log") 
    logFiles+=("$LOGROOT/auth.log") 
    ;;
  iperf|iperf3)
    svcs+=("iperf3-server@") 
    ;;
esac

# Display the service status and logs
declare -a logs
for svc in "${svcs[@]}"; do
  Log "Service: $svc"
#  Log "--------------------"
  
  # Get service status, if requested
  if [ $svcStats ]; then
    Run systemctl status "$svc"
    echo
  fi

  # Get log from Journal
  Log "Journal:"
  Log "$(journalctl -u "$svc" | head -$numLines)"
done

# Display the log files
for logFile in "${logFiles[@]}"; do
  if [ -r "$logFile" ]; then
    Log "${logFile}:"
    Run tail -$numLines "$logFile"
    echo
  else
    [ -f "$logFile" ] \
      && LogDebug "Log file exists but is not readable: $logFile\n" \
      || LogDebug "Log file does not exist: $logFile\n" 
  fi
done
