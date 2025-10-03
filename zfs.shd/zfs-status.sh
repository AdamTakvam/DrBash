#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/general.sh"

declare -r APPNAME="zfs-status"

PrintHelp() {
  tabs 4
  Log "Shows the status of all ZFS drive pools configured on this computer."
  Log
  Log "$(Header "Usage:") $APPNAME [FLAGS] [POOL_ID]"
  Log
  Log "$(Header "FLAGS")\t(optional) Operational flags"
  LogTable "\t-e\tError-only mode. Suppress output if all pools are healthy.
\t-h\tPrint this help screen"
  Log
  LogTable "$(Header "POOL_ID")\t(optional) A specific pool to get the status of."
  Log
}

declare showHealthy=1

for p in "$@"; do
  case "$p" in
    "?" | -h | --help)
      PrintHelp
      exit 0 ;;
    -e)
      unset showHealthy ;;
    $(LogParamsCase))
      : ;;
    *)
      pool_id="$1" ;;
  esac
done

declare -ar FAILWORDS=(DEGRADED REMOVED OFFLINE)
declare -ar SUCCESSWORDS=(ONLINE)

# See if there are any errors on the storage arrays. If so, display the status.
statsDisplay="\n$(zpool status $pool_id)"
colorDisplay="$statsDisplay"

for word in "${FAILWORDS[@]}"; do
  wordColor="$(ColorText LRED $word -s)"
  colorDisplay="$(echo "$colorDisplay" | sed -E "s/$word/$wordColor/g")"
done

[ "$statsDisplay" != "$colorDisplay" ] && hasErrors=1

for word in "${SUCCESSWORDS[@]}"; do
  wordColor="$(ColorText LGREEN $word -s)"
  colorDisplay="$(echo "$colorDisplay" | sed -E "s/$word/$wordColor/g")"
done

if [ "$hasErrors" == "1" ] || [ "$showHealthy" == "1" ]; then
  Log "$colorDisplay"
fi

# hdd-info
