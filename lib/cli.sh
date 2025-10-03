
GetParamName() {
  if [[ "$1" =~ ^- ]] && [[ "$1" != -- ]]; then
    _arg="${1#*-}"
    printf "%s" "${_arg%%=*}"  
  else
    printf "%s" "$1"
  fi
 }

GetParamValue() {
  if [[ "$1" =~ = ]]; then
    printf "%s" "${1#*=}"
    return 0
  else
    printf ""
    return 1
  fi
}

# Combines individual simple flag parameters into one combined parameter
# This makes it easier for your script to accept both forms.
#   e.g. -t -y -p -> -typ
# + $@ = Individual parameters
# - stdout = The combined parameter
CombineParams() {
  local _param='-' _others=''
  if [ "$1" ]; then                                                                                                                                     for p in "$@"; do
      [[ "$p" =~ -[a-zA-Z0-9] ]] \
          && _param+="${p:1}" \
          || _others+="$p "
    done
    printf "%s" "$_param $_others"
    return 0
  else
    return 99
  fi
}

# Separates combined flag parameters into an array of simple parameters
# This makes it easier for your script to accept both forms.
# This is an alternative to CombineParams().
# The only real difference is which form is easiest to process in your script.
# So far, I think this one is the clear winner. If that holds true, CombineParams() may disappear.
# You've been warned!
#   e.g. -typ -> - t -y -p
# + $1 = Combined parameter
# + $2 = Name of array to hold the individual parameter names
SeparateParams() {
  combined="$1"

  for c in $combined; do
    echo $c
  done
}

# Parse parameters into an assoc. array
# Handles combined or separated parameter styles
#   with and without values
# Values must be separated with an equals sign =
# Values separated by spaces or combined with the parameter itself are NOT supported.
# + $1 = The name of an array defined in the caller's scope to populate with flags.
# + $2 = The name of an associative array to populate with named parameters.
# + $3 = The name of an array to populate with stand-alone/anonymous parameters.
# + $4 = The name of an array to store parameters that failed to parse correctly
# + $5 = The name of an array containing the parameters to be parsed. If you prefer to send them as a string, then:
#           echo -n "$*" | ParseParameters 'flags', 'named', 'anon' --
# + stdin = Source of standalone parameters (if -- specified)
# - retVal = Indicates whether or not the parameter list was parsed successfully.
#
# Parameter style   Parses As
# ---------------   ---------
# -a -b -c          ${1[0]}=a ${1[1}]=b ${1[2]}=c
# -abc              ${1[0]}=a ${1[1}]=b ${1[2]}=c 
# -a=value          ${2[a]}=value
# -a="v1 v2"        ${2[a]}="v1 v2"
# --name            ${1[0]}="name"
# --name='value'    ${2[name]}="value"
# --                ${3[@]}=(stdin)     (separate values indicated by spaces, quotes, or line feeds
# value1 value2     ${3[0]}="value1" ${3[1]}="value2"
# "value1 value2"   ${3[0]}="value1 value2"
#
# NOT supported    Why?
# -------------    ----
# -abc=z           Too ambuiguous. Short named arguments must be assigned individually (e.g. -a=z -b=z -c=z)
# -name            Will be parsed as -n -a -m -e
# --cool-name      Losing the spaces in a parameter string is a common error. Use underscore instead of hyphen in param names.
# --abc            Anything from -- until the nerxt space or = character is treated asd a long-form parameter namer.
# -a value         Would require client to submit a parameter schema in order to parse reliably.
# --name value     Same
#
ParseParameters() {
  [ -z "$4" ] && return 99

  # Init function parameters first
  local -n _flags="$1"
  local -n _named="$2" 
  local -n _anons="$3" 
  shift 3

  [[ "$1" == '--' ]] && local -a _params=($(cat)) \
                     || local -a _params=("$@")

  for p in "${_params[@]}"; do
    #printf "%s\n" "p=$p"

    pv="$(GetParamValue "$p")"   
    pn="$(GetParamName "$p")" 

    if [[ "$pn" =~ - ]]; then
      # Parameter names must not contain a dash after the first character
      _errors+=("$p")
    elif [[ "$p" =~ ^-- ]]; then
      if [[ "$p" == -- ]]; then
        # Special parameter
        _anons+=("$p")
      else
        # Long-form parameter
        [[ "$pv" ]] && _named[$pn]="$pv" \
                    || _flags+=("$pn")
      fi
    elif [[ "$p" =~ ^- ]]; then
      # Short parameters
      if [[ "$pv" ]]; then
        [[ ${#pn} == 1 ]] && _named[$pn]="$pv" \
                          || _errors+=("$p")
      else
        for pc in $(printf '%s' "$pn" | grep -o .); do
          _flags+=("$pn")
        done
      fi
    else
      # Anon parameter
      _anon+=("$pn")
    fi
  done
}
