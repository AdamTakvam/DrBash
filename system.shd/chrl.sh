#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"

declare -r RL3="multi-user.target"
declare -r RL5="graphical.target"

PrintHelp() {
  tabs 4 
  Log "Change the current runlevel of the operating system environment."
  Log "While Systemd does not strictly-speaking contain the concept of runlevels as SystemV did. it's not hard to figure out the equivalency, which is what this tool does."
  Log "Note: The change takes effect immediately, but does not persist after a reboot unless the -d (default) option is specified."
  Log
  Log "$(Header "Usage:") chrl [-h|-d] LEVEL"
  Log
  LogHeader "Parameters:"
  Log "\t-h\tDisplay this help text."
  Log "\t-d\tMake this runlevel the default when booting the system."
  LogTable "\tLEVEL
  \t\t'3' or 'console'\tConsole mode
  \t\t'5' or 'graphical'\tGraphical/Windowed mode
  \t\ttacos\tMmmm.... Tacos! Toggle the runlevel 3 <-> 5
  \t\t'?'\tPrint the current runlevel"
  Log
}

GetRunlevel() {
    # Proposal: To support many more window managers:
    rl5="$(systemctl list-units --type=service | grep -E 'gdm|sddm|lightdm|xdm|lxdm' | grep 'running')"
    # rl5="$(systemctl status sddm | grep "active (running)")"
    [ "$rl5" ] && echo "5" || echo "3"
}

SetRunlevel() {
  declare -l level="$1"

  # Perform the indicated task
  case "$level" in
    3 | console | terminal | shell | text | multi-user)
      [ $default ] && Run systemctl set-default $RL3
      Run systemctl isolate $RL3 ;;
    5 | graphical | windowed | ui | tacos)
      [ $default ] && Run systemctl set-default $RL5
      Run systemctl isolate $RL5 ;;
    ?)
      GetRunlevel ;;
    tacos)
      # Toggle the runlevel
      [ "$(GetRunlevel)" == '3' ] && SetRunlevel 5 || SetRunlevel 3 ;;
    *)
      LogError "Unknown runlevel indicated: $mode"
      PrintHelp
      return 1 ;;
  esac
}

# Read parameter list
while [ "$1" ]; do
  case "$1" in
    "" | -h | --help)
      PrintHelp
      exit 0 ;;
    -d)
      default=1
      shift ;;
    -*)
      LogError "Invalid option: $1"
      exit 1 ;;
    *)
      declare -l mode="$1"
      shift ;;
  esac
done

SetRunlevel "$mode"
