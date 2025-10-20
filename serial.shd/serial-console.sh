#!/bin/bash

set -o pipefail

source ${DRB_LIB:-/usr/local/lib}/drbash.sh
declare -r APPNAME="serial-console"

PrintHelp() {
  tabs 4
  Log "High-level serial port communications manager."
  Log "Includes features for diagnosing serial port connection/communication issues." 
  Log
  Log "$(Header "Usage:")\t$APPNAME [-h]"
  Log "\t\t$APPNAME [-t=<terminalemulator>] [-i=<interface>] [BAUDRATE|BAUDMODE|"all"]"
  Log
  Log "$(Header "Parameters") (all are optional):"
  LogTable "\t-h\tPrint this help text.
  \t-t\tSpecify which terminal emulator to use: "screen" (default) or "minicom"
  \t-i\tInterface to use for connection (e.g. ttyS1, ttyUSB0, etc) (default=ttyS1)
  \t\t'-i=?' to print a list of likely interfaces.
  \tBAUDRATE\tThe baud rate for the serial connection. (default=9600)
  \tBAUDMODE\tA number 1 through 11 identifying the baud rate corresponding to rates 1200 through 921600. 
  \t\tIf 'all' is specified for the BAUDMODE, then all 11 baud rates will be attempted in descending order. 
  \t\tNote that this is an interactive process. 
  \t\tYou must test then exit the serial terminal with each successive attempt."
  Log
  Log "$(Header "Note:") To exit the screen terminal, type: <CTRL>-A then \\. Type 'y' when asked to confirm."
  Log "      To exit the minicom terminal, type: <CTRL>-A then X. Press <CR> when asked to confirm."
}

declare -r mcConfigName="serial-console"

# Write Minicom's config file
# $1 = baud rate
# $2 = interface
#      Other params potentially configurable at a later date
# returns: status of config file write operation
# stdout: N/A
configMC() {
  baudrate=${1:-9600}
  dev="/dev/$2"
  bits=8
  parity='N'
  stopbits=1

  config="# Machine-generated file - use \"minicom -s\" to change parameters. \
pu port             $dev \
pu baudrate         $baudrate \
pu bits             $bits \
pu parity           $parity \
pu stopbits         $stopbits"

  sudo bash -c "echo \"$config\" > /etc/minicom/minirc.$mcConfigName"
  return $?
}

# Convert baud mode to baud rate
# If baud rate is passed in, it is returned back as-is.
# $1 = baud rate or mode
# returns: success/fail
# stdout: baud rate
GetBaud() {
  declare -r def_baud=9600

  case "$1" in
    1)
      echo "1200" ;;
    2)
      echo "2400" ;;
    3)
      echo "4800" ;;
    4)
      echo "9600" ;;
    5)
      echo "19200" ;;
    6)
      echo "38400" ;;
    7)
      echo "57600" ;;
    8)
      echo "115200" ;;
    9)
      echo "230400" ;;
    10)
      echo "460800" ;;
    11)
      echo "921600" ;;
    *)
      if [ "$1" ]; then
        if (( $1 >= 1200 && $1 <= 921600 )); then
          echo $1
        else
          LogError "Error: Invalid baud rate or baud mode indicated: $1"
          PrintHelp | LogError
          return 1
        fi
      else
        echo $def_baud
      fi ;;
  esac
  return 0
}

# Runs the desired serial terminal
# $1 = terminal choice
# $2 = interface
# $2 = baud rate
# returns=success/fail
# stdout=N/A
RunTerminal() {
  Log "Launching $1 on $2 at $3 baud..."

  case "$1" in
    screen)
      Log "To exit the screen terminal, type: <CTRL>-A then \\. Type 'y' when asked to confirm."
      sleep 5
      sudo screen /dev/$2 $3
      return $? ;;
    minicom)
      Log "To exit the minicom terminal, type: <CTRL>-A then X. Press <CR> when asked to confirm."
      sleep 5
      configMC $2 $3
      sudo minicom "$mcConfigName"
      return $? ;;
    *)
      LogError "Terminal "${1:-<unspecified>}" is not supported."
      PrintHelp
      exit 1 ;;
  esac
}

ParseParams() {
  [ -z "$1" ] && return 0

  for p in $@; do
    local pn=GetParamName "$p"
    local pv=GetParamValue "$p"

    case "$pn" in
      t)
        terminal="$pv" ;;
      i)
        interface="$pv" ;;
      h)
        PrintHelp
        exit 0 ;;
      *=*)
        LogError "Unrecognized parameter: $p" ;;
      *)
        baudParam="$p" ;;
    esac
  done
}

declare -g terminal="screen"
declare -g interface="ttyS1"
declare -g baudParam="9600"

ParseParams

# If user doesn't know which interface to use, help them out
if [[ "$interface" =~ '?' ]]; then
  PS3="Select an interface: "
  declare -a interfaces=($(ls /dev/tty* | grep -E '/dev/tty[A-Z]+' | sed -E 's|/dev/||'))
  select interface in "${interfaces[@]}"; do 
    [ "$interface" ] && break
  done
fi

if [ "${baudParam,,}" == "all" ]; then
  declare -i baudMode
  for baudMode in {11..1}; do
    baud=$(GetBaud $baudMode)
    declare -l connect
    Log "Do you want to attempt to connect at $baud baud (Y/n/q)? " 
    read -n1 -t5 connect; echo
    case $connect in
      n)
        continue ;;
      q)
        if(( $baudMode < 11 )); then
          baud=$(GetBaud $((baudMode+1)))
          Log "Reminder: The last baud rate you connected with was: $baud";
        fi
        exit 0 ;;
      *)
        RunTerminal $terminal $interface $baud ;;
    esac
  done
else 
  baud="$(GetBaud "$baudParam")"
  [ $? == 0 ] && RunTerminal $terminal $interface $baud
  exit $?
fi
