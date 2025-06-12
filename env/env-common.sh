# Gets the current interpretting shell
#   Currently only supports bash and zsh  
# - stdout: 'bash' or 'zsh'
GetShell() {
  isbash="$(echo "$SHELL" | grep 'bash' )"
  [ "$isbash" ] && echo "bash" || echo "zsh"
}

# Determines whether the currently excecuting shell is Bash or not
IsBashShell() {
  if [ "$(GetShell)" == 'bash' ]; then
    echo "true"
    return 0
  else
    return 1
  fi
}

# Determines whether the currently excecuting shell is zsh or not
IsZshShell() {
  if [ "$(GetShell)" == 'zsh' ]; then
    echo "true"
    return 0
  else
    return 1
  fi
}
