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
# This is functionally the opposite of CombineParams().
#   e.g. -abc -> -a -b -c
# + $1 =  Name of array to hold the individual parameter names
# + $2+ = Combined parameters
#         This command only acts on parameters that begin with a single dash.
#         All others are returned in the same condition they were received.
# - stdout = list of null-delimited parameters
SeparateParameters() {
  [[ $NUM_FLAG_CHARS == 1 ]] || return 0  # Don't separate params if caller allows multi-char flags

  local -n _outParams="$1"; shift         # array
  local -i _result=1

  for param in "$@"; do
    echo "SeparateParameters: param(1) = $param"
    local tok=$(Trim $param)
    echo "SeparateParameters: param(2) = $param"
    case "$tok" in
      --*)
        _outParams+=("$tok") ;;
      -*=*)
        _outParams+=("$tok") ;;
      -*)
        local -a _chars=()
        GetChars '_chars' "$tok"
        for c in "${_chars[@]}"; do
          case $c in ' ' | -) ;;
            *)
              _outParams+=("-$c")
              _result=0 ;;
          esac
        done ;;
      *)
        _outParams+=("$tok") ;;
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

  local -a _TOKENS=()
  SeparateParameters _TOKENS "$@"

  # Build argv to parse from either a named array ($5) or stdin when $5 == "--"
  if IsPipedDataParam "${_TOKENS[-1]}"; then
    unset '_TOKENS[-1]'
    # Read stdin as a single line respecting shell-like word splitting
    # Use read -r -a to split like the shell (handles quoted values inside the line)
    local _line=''
    local IFS= 
    read -r _line
    # If multiple lines, slurp the rest appended with spaces
    if [[ ! -t 0 ]]; then
      local _extra
      while IFS= read -r _extra; do
        _line+=" $_extra"
      done
    fi
    # Now split into tokens using bash itself
    _TOKENS+=(${_line})
  fi

  # Parse
  _parse_tokens _TOKENS
  return $?
}

declare -g SOURCED_PARAM="^^^sourced^^^"

# Dr. Bash's version of source or .
=() {
  source "$*" $SOURCED_PARAM
}
