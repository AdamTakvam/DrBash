#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/run.sh"

# Environment Variables
: ${LOGROOT:="/var/log"}
: ${HOSTNAME:=`hostname`}
: ${PLEX_HOME:="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/"}

# Constants
declare -r APPNAME="showlog"
declare -r LOGROOT="/var/log"

PrintHelp() {
  tabs 4
  Log "Displays the log for the indicated service. Some known services will display accurate results. For all others, the script makes reasonable guesses to find the logs."
  Log
  Log "$(Header "Usage:") $APPNAME [FLAGS] SERVICE"
  Log
  LogHeader "FLAGS:"
  LogTable "\t-h\tDisplay this help screen.
  \t-s\tAlso display service status (not applicable in all cases)
  \t-n #\tNumber of most recent log message to display (default: 40)
  \t-v\tVerbose output
  \t-vv\tDebug mode"
  Log
  Log "$(Header "SERVICE:")\tThe name of a service (aka "unit")"
  Log
  LogHeader "Supported Services:"
  LogTable "\tsystem\tKernel service
  \tapt\tSoftware installation
  \tplex\tPlex media server
  \tsamba\tWindows interop service
  \tnet\tLinux networking subsystem
  \tiperf\tPerformance benchmarking tool
  \t*\tAnything else will be attemped on a best-effort basis"
  Log
  LogHeader "Environment Variables:"
  LogTable "\tLOGROOT\tThe location of your log files (default: /var/logs)
  \tHOSTNAME\tThe name of this computer (if unset, we'll get it another way. Don't sweat it.)
  \tPLEX_HOME\tThe location of the Plex Media Server data directoty (default: /var/lib/plexmediaserver/Library/Application Support/Plex Media Server/"
  Log
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
  LogUnderline "Service: $svc" "#"
  
  # Get service status, if requested
  if [ $svcStats ]; then
    Run systemctl status "$svc"
    Log
  fi

  # Get log from Journal
  LogUnderline "Journal: $svc"
  Log "$(journalctl -u "$svc" | head -$numLines)"
done

# Display the log files
for logFile in "${logFiles[@]}"; do
  if [ -r "$logFile" ]; then
    LogUnderline "${logFile}:"
    Run tail -$numLines "$logFile"
    Log
  else
    [ -f "$logFile" ] \
      && LogDebug "Log file exists but is not readable: $logFile\n" \
      || LogDebug "Log file does not exist: $logFile\n" 
  fi
done
