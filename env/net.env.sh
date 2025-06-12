lsports() {
  if [ -z "$1" ]; then
    sudo ss -nlp
  else
    sudo ss -nlp | grep -i "$1"
  fi
}
