#!/bin/bash

source "${DRB_LIB:-/usr/local/lib}/run.sh"
declare -r APPNAME="sensors-color"

Require lm-sensors

Help() {
  tabs 4
  Log "Displays the temperature of every CPU core present in the system. Temperatures are color-coded to reflect how close a core is to overheating."
  Log
  LogTable \
"\tNo Color\t=\tTemperature is within normal operating range.
\t$(ColorText YELLOW Yellow)\t=\tTemperature is considered high and should be reduced.
\t$(ColorText LRED Red)\t=\tTemperature is critical and must be reduced immediately to prevent permanent hardware damage." 
  Log
  Log "$(Header "Usage:") $APPNAME [OPTS]"
  Log
  Log "$(Header "OPTS:")"
  LogParamsHelp
  Log
}

testData="coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +96.0°C   (high = +96.0°C, crit = +102.0°C)
Core 0:        +103.0°C  (high = +96.0°C, crit = +102.0°C)
Core 1:        +97.0°C   (high = +96.0°C, crit = +102.0°C)
Core 2:        +55.0°C   (high = +96.0°C, crit = +102.0°C)
Core 3:        +101.0°C  (high = +96.0°C, crit = +102.0°C)
Core 4:        +54.0°C   (high = +96.0°C, crit = +102.0°C)
Core 5:        +100.0°C  (high = +96.0°C, crit = +102.0°C)
 
coretemp-isa-0001
Adapter: ISA adapter
Package id 1:  +95.0°C   (high = +96.0°C, crit = +102.0°C)
Core 0:        +47.0°C   (high = +96.0°C, crit = +102.0°C)
Core 1:        +102.0°C  (high = +96.0°C, crit = +102.0°C)
Core 2:        +43.0°C   (high = +96.0°C, crit = +102.0°C)
Core 3:        +103.0°C  (high = +96.0°C, crit = +102.0°C)
Core 4:        +52.0°C   (high = +96.0°C, crit = +102.0°C)
Core 5:        +101.0°C  (high = +96.0°C, crit = +102.0°C)"

TempDisplay() {
  local temp="$1"
  [ -z "$temp" ] \
    && printf "%s" "??" \
    || printf "%s" "+$temp.0°C"
}

TempExpr() {
  local temp="$1"
  [ -z "$temp" ] \
    && printf "%s" "??" \
    || printf "%s" "\+$temp.0°C\s"
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  Help
  exit 0
fi

# 1. Extract the package temps
declare -a temps
[ "$(LogDebugEnabled)" ] \
  && sensorData="$testData" \
  || sensorData="$(sensors)"
IFS=$'\n' temps=($(echo "$sensorData" | \
  awk '/Package/ { print $4 }' | \
  sed -E 's/\+([0-9]*).*/\1/'))

# 2. Extract the core temps
IFS=$'\n' temps+=($(echo "$sensorData" | \
  awk '/Core/ { print $3 }' | \
  sed -E 's/\+([0-9]*).*/\1/'))

LogVerbose "temps = $(echo -n "${temps[*]}" | tr $'\n' ',')"

# 3. Extract the high and critical temperature values
declare -i htemp ctemp
IFS=$'\n' htemp=($(echo "$sensorData" | \
  awk '/Package/ { print $7 }' | \
  head -n1 | \
  sed -E 's/\+([0-9]*).*/\1/'))

IFS=$'\n' ctemp=($(echo "$sensorData" | \
  awk '/Package/ { print $10 }' | \
  head -n1 | \
  sed -E 's/\+([0-9]*).*/\1/'))

LogVerbose "high temp = $htemp\ncrit temp = $ctemp\n" 

# 4. Color the temps appropriately
# colorTemps is an associative array because we must'nt
#   duplicate temperature values in the collection.
declare -i temp
declare -A colorTemps=()
for temp in "${temps[@]}"; do

  # If we've already done this temp value, don't do it again
  [ "${colorTemps["$temp"]}" ] && continue
  
  unset normal
  if (( $temp >= $ctemp )); then
    colorTemps["$temp"]="$(ColorText -e LRED "$(TempDisplay $temp)")"
    critical=1
  elif (( $temp >= $htemp )); then
    colorTemps["$temp"]="$(ColorText -e YELLOW "$(TempDisplay $temp)")"
    high=1
  else
    normal=1
  fi

  if [[ $normal != 1 ]]; then
    sensorData="$(echo "$sensorData" | \
      sed -E "s/$(TempExpr $temp)/${colorTemps["$temp"]} /g")"
  fi
done

Log "$sensorData"

[ $critical ] && exit 2
[ $high ] && exit 1
