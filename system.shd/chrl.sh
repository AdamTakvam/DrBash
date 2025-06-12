#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"

declare -r RL3="multi-user.target"
declare -r RL5="graphical.target"

PrintHelp() {
  tabs 4 
  echo "Change the current runlevel of the operating system environment."
  echo "While SystemD does not strictly-speaking contain the concept of runlevels as SystemV did. it's not hard to figure out the equivalency, which is what this tool does."
  echo "Note: The change takes effect immediately, but does not persist after a reboot unless the -d (default) option is specified."
  echo
  echo "Usage: chrl [-h|-d] LEVEL"
  echo
  echo "Parameters:"
  echo -e "\t-h\tDisplay this help text."
  echo -e "\t-d\t(optional) Make the new runlevel the default when booting the system."
  echo -e "\tLEVEL\tOnly the bootable runlevels and \'?\' are supported:"
  echo -e "\t\t'3' or 'console'\tConsole mode"
  echo -e "\t\t'5' or 'graphical'\tGraphical/Windowed mode"
  echo -e "\t\t'?'\t\t\t\t\tPrint the current runlevel"
  echo
}

declare -l mode

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
      mode="$1"
      shift ;;
  esac
done

# Perform the indicated task
case "$mode" in
  3 | console | terminal | shell | text | multi-user)
    [ $default ] && Run systemctl set-default $RL3
    Run systemctl isolate $RL3 ;;
  5 | graphical | windowed | ui | tacos)
    [ $default ] && Run systemctl set-default $RL5
    Run systemctl isolate $RL5 ;;
  ?)
    rl5="$(systemctl status sddm | grep "active (running)")"
    [ "$rl5" ] && echo "5" || echo "3" ;;
  *)
    LogError "Unknown runlevel indicated: $mode"
    PrintHelp
    return 1 ;;
esac
