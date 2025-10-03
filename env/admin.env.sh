# Administrative tools
# Sourced in .bashrc to use from command line

# source "${DRB_ENV:-.}/env-common.sh"

# Run vim as root, but still use the current user settings
# $1 = File you wish to edit
sudovim() {
  sudo -E vim -u "$HOME/.vimrc" "$@"
}
# export -f sudovim

# Delete files as root (workaround for not having env variables set correctly)
sudorm() {
  sudo -E rm "$@"
}

sudomv() {
  # Future: detect glob pattern or regex in destination
  #   and launch better tools to handle intelligent moves/renames
  sudo -E mv "$@"
}

sudocp() {
  sudo -E cp "$@"
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
whatprovides() {
  dpkg -S "$(/usr/bin/which "$1")" | cut -d: -f1
}
# export -f exefrom
