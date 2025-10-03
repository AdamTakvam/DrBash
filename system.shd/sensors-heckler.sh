#!/usr/bin/env bash
# rude-hot-package.sh — yell when *Package id N* exceeds threshold
# Requires: lm-sensors
# Source DrBash core:
#   source "$DRB_LIB/drbash.sh"

set -Eeuo pipefail

# --- DrBash bootstrap ---
: "${DRB_LIB:?Set DRB_LIB to your DrBash lib dir}"
# shellcheck disable=SC1091
source "$DRB_LIB/drbash.sh"

# Ensure dependency (your Require will install or exit)
Require lm-sensors

Help () {
	LogHeader "rude-hot-package.sh — CPU Package temp heckler"
	Log "Rudely prints to all your PTYs when CPU *Package id N* crosses a threshold."
	Log "Sensors-only. Background-safe (nohup/&/disown). Hysteresis to avoid spam."
	Log
	LogHeader "Synopsis"
	Log "./rude-hot-package.sh <THRESH_C|###C|###F> [interval_s] [hysteresis_C]"
	Log
	LogHeader "Options"
	LogTable $'Option\tDescription\tDefault\n'\
'-t/positional 1\tThreshold (C or F; e.g., 96, 96C, 205F)\t—\n'\
'-i/positional 2\tPoll interval (seconds)\t5\n'\
'-y/positional 3\tHysteresis before re-arming (°C)\t3\n'\
'--quit-file PATH\tCreate this file to stop the watcher\t/tmp/rude-hot-package.quit'
	Log
	LogHeader "Behavior"
	Log "• Watches ONLY: “Package id N:  +##.#°C …” from `sensors`"
	Log "• Alerts once on ≥ threshold; re-arms after cooling to ≤ (threshold − hysteresis)"
	Log "• Broadcasts to all current PTYs from 'who' (so alerts still show when detached)"
	Log
	LogHeader "Examples"
	Log "nohup ./rude-hot-package.sh 96 2 3 >/dev/null 2>&1 & disown"
	Log "touch /tmp/rude-hot-package.quit   # graceful stop"
}

# --- Args ---
thr_raw="${1-}"
if [[ -z "$thr_raw" ]] || [[ "$thr_raw" == "-h" ]] || [[ "$thr_raw" == "--help" ]]; then
	Help; exit $([[ -z "$thr_raw" ]] && echo 2 || echo 0)
fi
interval="${2-5}"
hyst="${3-3}"
QUIT_FILE="${QUIT_FILE:-/tmp/rude-hot-package.quit}"

# --- Parse threshold -> int °C ---
parse_c () {
	local v=${1^^}
	if [[ $v =~ ^([0-9]+)[[:space:]]*C?$ ]]; then
		echo "${BASH_REMATCH[1]}"
	elif [[ $v =~ ^([0-9]+)[[:space:]]*F$ ]]; then
		awk -v f="${BASH_REMATCH[1]}" 'BEGIN{ printf("%d", (f-32)*5/9 + 0.5) }'
	else
		LogColor RED "ERROR: Bad threshold: '$1' (use 96, 96C, or 205F)"; exit 2
	fi
}
thr="$(parse_c "$thr_raw")"
[[ $interval =~ ^[0-9]+$ ]] || { LogColor RED "ERROR: interval must be integer seconds"; exit 2; }
[[ $hyst =~ ^[0-9]+$     ]] || { LogColor RED "ERROR: hysteresis must be integer °C"; exit 2; }

# --- Utilities ---
ptys () { Run -u who | awk '{print $2}' | sort -u; }

read_pkg_max () {
	Run -u sensors 2>/dev/null | awk '
	BEGIN{max=-1; lbl=""}
	/^Package id [0-9]+:.*°C/ {
	  if (match($0, /[+-]?[0-9]+(\.[0-9]+)?°C/)) {
	    v=substr($0,RSTART,RLENGTH); gsub(/[^0-9.]/,"",v)
	    c=int(v + 0.5)
	    if (c > max) { max=c; lbl=substr($0, 1, index($0, ":")-1) }
	  }
	}
	END{
	  if (max >= 0) { printf "%s\t%d\n", lbl, max; exit 0 }
	  else { exit 1 }
	}'
}

# --- Preflight (no sudo required) ---
Preflight () {
	if ! Run -u sensors | grep -qE '^Package id [0-9]+:'; then
		LogColor RED "WARNING: No 'Package id N' labels found in sensors output."
		Log "You can still run it, but it won’t alert until those labels exist."
	fi
	local have_pty=0
	for p in $(ptys); do
		if [[ -c "/dev/$p" && -w "/dev/$p" ]]; then have_pty=1; break; fi
	end
	if (( ! have_pty )); then
		LogColor RED "WARNING: No writable PTYs detected. Open a terminal so alerts have a target."
	fi
}
Preflight

# --- Announce ---
	LogHeader "CPU Package Heckler"
	Log "Threshold: ${thr}°C  Interval: ${interval}s  Hysteresis: ${hyst}°C"
	Log "Quit file: $QUIT_FILE"
	Log "PID: $$"
	Log

# --- Main loop ---
armed=1
while :; do
	[[ -e "$QUIT_FILE" ]] && { Log "Quit file detected. Exiting."; exit 0; }

	if out="$(read_pkg_max)"; then
		IFS=$'\t' read -r hotlbl hotc <<<"$out"
		if (( armed )); then
			if (( hotc >= thr )); then
				for p in $(ptys); do
					[[ -c "/dev/$p" ]] || continue
					printf "\a[%(%F %T)T] YOUR %s IS %d°C >= %d°C — BACK OFF, PYROMANIAC.\r\n" -1 "$hotlbl" "$hotc" "$thr" >"/dev/$p" 2>/dev/null || true
				done
				armed=0
			fi
		else
			(( hotc <= thr - hyst )) && armed=1
		fi
	fi

	sleep "$interval"
done

