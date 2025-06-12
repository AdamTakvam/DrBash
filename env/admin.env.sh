# Administrative tools
# Sourced in .bashrc to use from command line

# source "${USERENV:-.}/env-common.sh"

# Run vim as root, but still use the current user settings
# $1 = File you wish to edit
sudovim() {
  [ "$1" ] && sudo vim -u "$HOME/.vimrc" "$1"
}
# export -f sudovim

# Delete files as root (workaround for not having env variables set correctly)
sudorm() {
  if [ "$2" ]; then
    sudo -E rm $1 "$2"
  elif [ "$1" ]; then
    sudo -E rm "$1"
  else
    echo "Error: No target specified"
  fi
}

killproc() {
  process="$1"
  [ -z "$process" ] && { echo "Error: No process name specified"; return 1; }

  sudo bash -c "ps -ef | grep "$process" | awk '{ print $2 }' | xargs kill"
}

# Limit how much CPU time is allocated to the specified process
# $1 = Process name or regex or PID
throttle() {
  declare -i pid=$(high_cpu_pid "$1")
  sudo nohup cpulimit -p $pid -l 50 -m -b
}
# export -f throttle

# Print the PID of the process currently consuming the most CPU
# $1 = (optional) Process name or regex or PID
# stdout = PID of process matching the given expression using the most CPU 
high_cpu_pid() {
  if [ -z "$1" ]; then
    ps -eo pcpu,pid,args | sort -n -r | head -n 1 | awk '{ print $2 }'
  else
    ps -eo pcpu,pid,args | grep -i "$1" | sort -n -r | head -n 1 | awk '{ print $2 }'
  fi
}
# export -f high_cpu_pid

# Lists the executable files installed by the given package
# + $1 = The package that you want to run stuff from
# - stdout: A list of hot and juicy executables
exefrom() {
  dpkg -L "$1" | xargs file | grep executable | awk -F':' '{ print $1 }'
}
# export -f exefrom
