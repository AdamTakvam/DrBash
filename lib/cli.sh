# vim: filetype=bash

[[ -n $__cli ]] && return 0
declare -g __cli=1

declare -g NUM_FLAG_CHARS=1

# Determines whether the given parameter is a valid short or long-form flag
IsFlagParam() { 
  [[ "$1" =~ ^-[A-Za-z0-9_]{1,$NUM_FLAG_CHARS}$ ]] || \
  [[ "$1" =~ ^--[A-Za-z0-9_]+$ ]]
}           
  
# Determines whether the given parameter is a valid short or long-form named parameter
IsNamedParam() { 
  [[ "$1" =~ ^-[A-Za-z0-9_]{1,$NUM_FLAG_CHARS}=.*$ ]] || \
  [[ "$1" =~ ^--[A-Za-z0-9_]+=.*$ ]]
} 

# Determines whether the given parameter is stand alone
IsStandAloneParam() {
  [[ "$1" != -* ]]
}

# Determines whether the given parameter is the piped data flag
IsPipedDataParam() {
  [[ "$1" == -- ]]
}

# Returns the name portion of a flag or named parameter. e.g.:
# -h     -> h    (0)
# -i=3   -> i    (0)
# --help -> help (0)
# --ab=z -> ab   (0)
# *      -> ''   (1)
# a.txt  -> ''   (1)
# a=b    -> ''   (1)
# + $1 = The command-line parameter
# - stdout = The parameter name
# - retVal = 0: Parameter is a flag or named parameter | 1 : Parameter is empty or standalone
GetParamName() {
  if IsFlagParam "$1" || IsNamedParam "$1"; then
    _arg="${1##*-}"
    printf "%s" "${_arg%%=*}"  
    return 0
  else
    return 1
  fi
 }

# Returns the value portion of a named parameter. e.g.:
# -h     -> '' (1)
# -i=3   -> 3  (0)
# --help -> '' (1)
# --ab=z -> z  (0)
# *      -> '' (1)
# a.txt  -> '' (1)
# a=b    -> '' (1)
# + $1 = The command-line parameter
# - stdout = The parameter name
# - retVal = 0: Parameter is a named parameter | 1 : Parameter is anything else
GetParamValue() {
  if IsNamedParam "$1"; then
    printf "%s" "${1##*=}"
    return 0
  else
    return 1
  fi
}

# Internal: Reads stdin and splits it into words the way the shell would
#   (honoring '...', "..." and \ escapes) WITHOUT evaluating anything in it.
# + $1 = The name of an array to receive the words
# + stdin = The text to split
_Cli_ReadStdinWords() {
  local -n _words="$1"
  local _w
  _words=()
  while IFS= read -r -d '' _w; do
    _words+=("$_w")
  done < <(xargs -r printf '%s\0')
}

# Combines individual simple flag parameters into one combined parameter
# This makes it easier for your script to accept both forms.
#   e.g. -t -y -p -> -typ
# Everything else (named params, --long params, values) keeps its position.
# The combined flag takes the position of the first simple flag.
#   e.g. -a=1 -b -c --long xyz -> -a=1 -bc --long xyz
# + $@ = Individual parameters, or -- as the last one to also read parameters from stdin
# + stdin = More parameters (if -- specified)
# - stdout = The parameters, space-separated, with simple flags combined
CombineParams() {
  (( $# )) || return 99

  local -a _in=("$@") _out=()
  if IsPipedDataParam "${_in[-1]}"; then
    unset '_in[-1]'
    local -a _stdin
    _Cli_ReadStdinWords _stdin
    _in+=("${_stdin[@]}")
  fi

  local _flags='' p
  local -i _slot=-1
  for p in "${_in[@]}"; do
    if [[ "$p" =~ ^-[a-zA-Z0-9]+$ ]]; then
      if (( _slot < 0 )); then
        _slot=${#_out[@]}
        _out+=("")
      fi
      _flags+="${p:1}"
    else
      _out+=("$p")
    fi
  done
  (( _slot >= 0 )) && _out[_slot]="-$_flags"

  local IFS=' '
  printf "%s" "${_out[*]}"
}

# Separates combined flag parameters into an array of simple parameters
# This makes it easier for your script to accept both forms.
# This is functionally the opposite of CombineParams().
#   e.g. -abc -> -a -b -c
# + $1 =  Name of array to hold the individual parameter names
# + $2+ = Combined parameters
#         This command only acts on parameters that begin with a single dash.
#         All others are returned in the same condition they were received.
# - stdout = list of null-delimited parameters
SeparateParameters() {
  local -n _outParams="$1"; shift         # array

  # Don't separate params if caller allows multi-char flags
  if [[ $NUM_FLAG_CHARS != 1 ]]; then
    _outParams+=("$@")
    return 1
  fi

  local -i _result=1
  local param c
  for param in "$@"; do
    case "$param" in
      --* | -*=*)
        _outParams+=("$param") ;;
      -?*)
        local -a _chars=()
        GetChars '_chars' "${param:1}"
        for c in "${_chars[@]}"; do
          case "$c" in 
            ' ' | -) ;;
            *)
              _outParams+=("-$c")
              _result=0 ;;
          esac
        done ;;
      *)
        _outParams+=("$param") ;;
    esac
  done
  return $_result
}

# Parse parameters into an assoc. array
# Handles combined or separated parameter styles
#   with and without values
# Values must be separated with an equals sign =
# Values separated by spaces or combined with the parameter itself are NOT supported.
# + $1 = The name of an array defined in the caller's scope to populate with flags.
# + $2 = The name of an ASSOCIATIVE (i.e declare -A) array to populate with named parameters.
# + $3 = The name of an array to populate with stand-alone/anonymous parameters.
# + $4+ = The parameters to be parsed or -- to read from stdin.
# + stdin = Source of parameters (if -- specified).
# - retVal = Indicates whether or not the parameter list was parsed successfully.
#
# Parameter style   Parses As
# ---------------   ---------
# -a -b -c          ${1[0]}=a ${1[1}]=b ${1[2]}=c
# -abc              ${1[0]}=a ${1[1}]=b ${1[2]}=c 
# -a=value          ${2[a]}=value
# -a="v1 v2"        ${2[a]}="v1 v2"
# --name            ${1[0]}=name
# --name=value      ${2[name]}=value
# --name="v1 v2"    ${2[name]}="v1 v2"
# --                Substituted for the contents of stdin and parsed the same as if they were specified on the command line
# -a --             -a + stdin is parsed the same as if it were specified on the command line
# value1 value2     ${3[0]}=value1 ${3[1]}=value2
# "value1 value2"   ${3[0]}="value1 value2"
#
# NOT supported     Why?
# -------------     ----
# -abc=z            Too ambiguous. Short named arguments must be assigned individually (e.g. -a=z -b=z -c=z)
# -name             Will be parsed as -n -a -m -e
# --cool-name       Losing the spaces in a parameter string is a common error. Use underscore instead of hyphen in param names.
# --abc             Anything from -- until the next space or = character is treated as a long-form parameter name.
# -a value          Would require client to submit a parameter schema in order to parse reliably.
# --name value      Same
# -- value          Unlike many othe GNU tools, we simply don't roll like this. 
#                   -- must be the last parameter and it always means "read from stdin", NOT "I'm done with the flags list".
ParseParameters() {
  # Create namerefs to caller's arrays/assoc
  local -n _FLAGS="$1"  || return 99
  local -n _NAMED="$2"  || return 99
  local -n _ANON="$3"   || return 99
  shift; shift; shift; # No, it isn't equivalent to 'shift 3', thankyouverymuch

  # -------- helpers --------
  
  _parse_tokens() {
    local -n tokens="$1"
    local tok

    for tok in "${tokens[@]}"; do
      # "--" is NOT allowed mid-stream
      if IsPipedDataParam "$tok"; then
        LogError "-- can only appear as the last element in the parameter list."
        return 1
      elif IsFlagParam "$tok"; then
        local pn="$(GetParamName "$tok")"
        _FLAGS+=("$pn")
      elif IsNamedParam "$tok"; then
        local pn="$(GetParamName "$tok")"
        local pv="$(GetParamValue "$tok")"
        _NAMED[$pn]="$pv"
      elif IsStandAloneParam "$tok"; then
        _ANON+=("$tok")
      else
        LogError "Invalid parameter syntax: $tok"
        return 1
      fi
    done
  }

  # If the last parameter is --, replace it with the words read from stdin.
  # This happens BEFORE separating, so that stdin gets the exact same treatment
  #   as parameters given on the command line (e.g. -abc -> -a -b -c).
  local -a _ARGS=("$@")
  if (( ${#_ARGS[@]} )) && IsPipedDataParam "${_ARGS[-1]}"; then
    unset '_ARGS[-1]'
    local -a _stdin
    _Cli_ReadStdinWords _stdin
    _ARGS+=("${_stdin[@]}")
  fi

  local -a _TOKENS=()
  SeparateParameters _TOKENS "${_ARGS[@]}"

  # Parse
  _parse_tokens _TOKENS
  return $?
}

declare -g SOURCED_PARAM="^^^sourced^^^"

# Dr. Bash's version of source or .
=() {
  source "$*" $SOURCED_PARAM
}
