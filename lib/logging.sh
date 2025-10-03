# The is the logging subsystem of Dr. Bash.
#
# The API supports logging to the console or to the Systemd Journal
#
# Note: If you encouter parameters or functions labeled as "internal use only"
#   you can use them, but be aware that they come with zero guarantee
#   that they won't suddenly change or be removed at any time.


[[ -n "$__logging" ]] && return
__logging=1

source "${DRB_LIB:=/usr/local/lib}/cli.sh"

#
# -------------------- Internal Use Only ---------------------------------------
#
_Log() {
  local _msg _param

  if [[ "$2" == -- ]]; then
    _msg="$(cat)"
    _param="$(GetParamName "$1")"; shift
  elif [[ "$1" == -- ]]; then
    _msg="$(cat)"
  elif [[ "$1" =~ ^-[a-zA-Z0-9]+ ]]; then
    _param="$(GetParamName "$1")"; shift
    _msg="$@"
  else
    _msg="$@"
  fi
  
  case "$_param" in
    lrn)
      [ "$_msg" ] && printf "%${COLUMNS}s" "$_msg" ;;
    lr)
      [ "$_msg" ] && printf "%${COLUMNS}s\n" "$_msg" \
                  || printf "\n" ;;
    ln)
      [ "$_msg" ] && printf "%s" "$_msg" ;;
    l)
      [ "$_msg" ] && printf "%s\n" "$_msg" \
                  || printf "\n" ;;
    n)
      [ "$_msg" ] && printf "%b" "$_msg" ;;
    "")
      [ "$_msg" ] && printf "%b\n" "$_msg" \
                  || printf "\n" ;;
    *)
      LogError "Unrecognized option ($_param) passed to Log()" ;;
  esac
}
export -f _Log

_Journal() {
  [ -z "$1" ] && { echo "Internal Error: logging._Journal() was called improperly!"; return 99; }
  local -l logLevel="$1"; shift

  unset param
  [ "$2" ] && { local param="$1"; shift; }
  local msg="$1"

  # If -- passed in, check stdin
  [ "$msg" == '--' ] && msg="$(cat)"

  if [ "$msg" ]; then 
    LogDebug "Calling: logger $param -p $logLevel "$msg""
    logger $param -p $logLevel "$msg"
  fi
}
export -f _Journal

_GetCaller() {
  local -i depth=0
  
  # Look for the first caller that isn't from this file
  while [[ "${BASH_SOURCE[$depth]}" =~ logging.sh ]]; do
    (( depth++ ))
  done

  local _file="${BASH_SOURCE[$depth]}"
  local _func="${FUNCNAME[$depth]}"
  local _line="${BASH_LINENO[$depth-1]}"

  # 99% of the time, it won't have a path anyway
  #   but just for uniformity's sake.
  _file="$(basename "$_file")"

  printf "%s" "$_file.${_func:-[main]}():$_line"
}
export -f _GetCaller

#
# -------------------- System Log / Journal ---------------------------------------
#

# Writes the specified message to the system log/journal
# + $1 = (optional) Parameters to pass to the logger command
# + $2 = The message to write or -- to send piped content
# + stdin = The message to write
# - journalctl = The message
Journal() {
  _Journal user.info "$@"
}
export -f Journal

# Writes the specified message to the system log/journal
# + $1 = (optional) Parameters to pass to the logger command
# + $2 = The message to write or -- to send piped content
# + stdin = The message to write
# - journalctl = The message
JournalError() {
  _Journal user.error "$@"
}
export -f JournalError

# Writes the specified message to the console and the system log
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = Ass and Pussy destructionThe message to write (supports escaped control characters) or -- to send piped content
# + stdin = The message to write (supports escaped control characters)
# + stdout = The message
# - journalctl = The message
LogTee() {
  Log "$@"
  Journal "$@"
}
export -f LogTee

# Writes the specified message to the console and the system log
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters) or -- to send piped content
# + stdin = The message to write (supports escaped control characters)
# + stderr = The message
# - journalctl = The message
LogErrorTee() {
  LogError "$@"
  JournalError "$@"
}
export -f LogErrorTee

#
# -------------------- Console Output ---------------------------------------
#

# Writes the specified message to the console
# Supports piped messages with or without other parameters when you specify --
# Calling Log with no parameters will generate a newline
# Escape sequences are interpreted by default unless you specify -l
# + $1 = (opt) INTERNAL parameters to apply to the log output
#        -c=CODE = Print message in color
#        -t=TITLE = Prefix TITLE to message
#        -s=STACK = Prefix STACK to message
# + $2 = (opt) EXTERNAL parameters to apply to log output
#        -n = Suppress newline
#        -l = Stop trying to be smart and output LITERALLY what I'm telling you!
#        -ln = Literal value with no newline
#        -lr = Literal and right-justified
#        -lrn = Literal and right-justified with no newline
# + $3 = The message to write or -- for stdin
# + stdin = The message to write
# - stdout = The message
Log() {
  LogQuietEnabled && return 0
  
#  LogDebugEnabled && printf "Log() called with %s parameters\n" $#  

  local _msg=""
  for p in "$@"; do
    if [[ "$p" =~ ^-[a-zA-Z0-9]+ ]]; then
      local pn="$(GetParamName "$p")"
      local pv="$(GetParamValue "$p")"
  
      # The parameters handled here are for internal use only
      case "$pn" in
        c)
          local _color="$pv"; shift ;;
        t)
          local _title="$pv"; shift ;;
        s)
          local _stack="${pv:-$(_GetCaller)}"; shift ;;
        *)
          if [ "$_params" ]; then
            LogError "Internal Error: Too many parameters passed to Log()"
            return 99;
          else
            local _params="-$pn"; shift 
          fi ;;
      esac
    fi
  done

  _msg+="$@"

  [[ "$_stack" ]] && _msg="$_stack | $_msg"
  [[ "$_title" ]] && _msg="$_title: $_msg"
  [[ "$_color" ]] && _msg="$(ColorText $_color "$_msg")"

  _Log $_params "$_msg"
  return $?
}
export -f Log

# Logs *exactly* what you pass in with no interpretation of anything
# + $1 = (opt) Parameter to control how the output is presented.
#        -n = Do not inject a newline after the message
# + $2 = The message to log
# + stdin = (alt) The message to write
# - stdout = Your exact message
LogLiteral() {
  [ "$1" == '-n' ] && _Log -ln "$2" \
                   || _Log -l "$1"
}
export -f LogLiteral

# Writes the specified message to stderr
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
#         -x will suppress color and stack trace output
# + $2 = The message to write (supports escaped control characters) or -- to send piped content
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogError() {
  # If caller is requesting the literal message, do not attempt to set color.
  [[ "$1" =~ l ]] || local _p1='-c=RED'
  LogDebugEnabled && local _p2="-s="
  Log '-t=Error' $_p1 $_p2 "$@" >&2
}
export -f LogError

# Logs a message to stderr without all of the pomp and circumstance of LogError
# This function is intended to be used exclusively in the situation where a function
#   must display output and also return a value.
LogErrorCovert() {
  _Log "$@" >&2
}
export -f LogErrorCovert

# Writes the specified message to the console if verbose logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# + $VERBOSE = Set to enable verbose logging
# - stdout = The message
LogVerbose() {
  if LogVerboseEnabled; then 
    [[ "$1" =~ l ]] || local p1='-c=PURPLE'
    LogDebugEnabled && local p2='-s=' 
    Log '-t=Verbose' $p1 $p2 "$@" 
  fi
}
export -f LogVerbose

# Writes the specified message to stderr if verbose logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogVerboseError() {
  # Explanation: There's only one reason to call this function.
  #   You're in a situation where you want to print verbose output 
  #   but you're in a function that also returns a value.
  #   So you're just doing an end-run around bash's silly limitations.
  #   Ergo, it's not truly an error.
  #   Any legitimate error should not be hidden from the user based on log level
  #   and thus should go through LogError().
  LogVerboseEnabled && LogErrorCovert "$@"
}
export -f LogVerboseError

# Writes the specified message to the console if debug logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $DEBUG = Set to enable debug logging
# - stdout = The message
LogDebug() {
  if LogDebugEnabled; then
    [[ "$1" =~ l ]] || local p1='-c=LGREEN'
    Log '-t=Debug' '-s=' $p1 "$@"
  fi
}
export -f LogDebug

# Writes the specified message to stderr if debug logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogDebugError() {
  # Explanation: See LogVerboseError()
  LogDebugEnabled && LogErrorCovert "$@"
}
export -f LogDebugError

#
# -------------------- Pretty Printing ---------------------------------------
#

# Writes the specified message formatted as a table to stdout.
# Message is formatted as a table using tabs (\t) to denote columns.
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stdout = The message
LogTable() {
  Log "$@" | FormatTable
}
export -f LogTable

# Writes the specified message formatted as a table to stderr
# Message is formatted as a table using tabs (\t) to denote columns.
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogTableError() {
  LogTable "$@" >&2
}
export -f LogTableError

# Writes the specified messages in columns to the terminal.
# If no column width is specified, when it will be assumed to be one character wider than the longest string in the left column values.
# + $1 = Name of an array containing the values to display in the left column
# + $2 = Name of an array containing the values to display in the right column
# + $3 = (optional) The width of the left column
LogTableLiteral() {
  local -n column1="$1"
  local -n column2="$2"
  local -i c1_width="$3"

  # Determine left column width, if not specified
  if [[ "$c1_width" == 0 ]]; then
    for v in "${column1[@]}"; do
      l=${#v}
      (( l > c1_width )) && c1_width=$(( l + 1 ))
    done
  fi

  # Determine total number of rows
  numRows=${#column1[@]}
  [[ ${#column2[@]} > $numRows ]] && numRows=${#column2[@]}

  # Display the table
  for (( i=0; i<$numRows; i++ )); do
    c1Val="${column1[$i]}"
    printf "%s%*s%s\n" "$c1Val" $(( c1_width - ${#c1Val} )) "${column2[$i]}"
  done
}
export -f LogTableLiteral

# Logs a message is the indicated color. 
# Source this file and run ShowColors() to see your options.
# This function is the top-level version of the inline ColorText() function.
# + $1 = The desired color
# + $2 = (optional) Any parameters you want to pass to Log()
# + $3 = The message
# - stdout = The message displayed in the specified color.
LogColor() {
  color=${1:-NC}
  Log -c=$color "$2"
}
export -f LogColor

# Gives the appearance of the passed-in text being in bold face.
# This function is intended to be a top-level call or alternative to Log().
# + $1 = The message to write or -- if stdin
# + stdin = The message to write 
# - stdout = The message
LogHeader() {
  [ -z "$1" ] && return 99
  Log -c=WHITE "$1"
}
export -f LogHeader

# Gives the appearance of the passed-in text being in bold face.
# Whether this effect works or not will depend on the color pallete 
#   of your terminal emulator. If white and light gray look the same
#   then this function will accomplish nothing.
# This functioun is intended to be called within quoted text.
# + $1 = The header/title text or -- if stdin.
# + stdin = The header/title text (in leiu of $1).
# - stdout = Your new far-more-magnanimous text!
Header() {
  Log -c=WHITE -n "$1"
}
export -f Header

# Alias for Header()
Bold() {
  Header "$1"
}
export -f Bold

# Formats your tab-delimited text into a table
# + stdin = Your complete single or multi-line text
# - stdout = Your text now formatted into columns
FormatTable() {
  column -t -s $'\t'
}
export -f FormatTable

# Writes the specified message in bold face to stderr
# Message is formatted as a table using tabs (\t) to denote columns.
# + $1 = (opt) parameters to apply to the Log command.
# + $2 = The message to write 
# + stdin = The message to write 
# - stderr = The message
LogHeaderError() {
  LogError "$(Log "$1" "$2" | Header --)"
}
export -f LogHeaderError

# Prints a log message visually set apart as a quote
# + $1 = (opt) parameters to apply to the Log command.
# + $2 = The message to write
# + stdin = (alt) The message to write
# - stdout = The message
LogQuote() {
  local _msg _params

  if [ "$2" ]; then
    _params="$1"
    _msg="$2"
  else
    _msg="$1"
  fi

  _msg=" | $_msg"
  Log $_params "$_msg"
}
export -f LogQuote

# Print message right-justified in the console window
# + $1 = (opt) Parameter to control how the output is presented.
#        -n = Do not inject a newline after the message
# + $2 = The message to log
# - stdout = Your exact message, right-justified
LogRight() {
  [ "$1" == '-n' ] && Log -lrn "$2" \
                   || Log -lr "$1"
}
export -f LogRight

# Print message with an underline effect
# Output will consume 2 rows of display
# Line will be the same length as your text
# + $1 = (opt) Display options
#         -c = Centered text
# + $2 = Message
# + $3 = (opt) Character to use for the underline effect
# - stdout = Your exact message with a row of = on the subsequent line
LogUnderline() {
  local msg
  local -i pad=0

  # 1. Calculate position
  # Centered?
  if [[ "$1" == '-c' ]]; then
    shift
    msg="$1"
    [[ -z "$msg" ]] && return 1
    pad=$(( ($COLUMNS - ${#msg}) / 2 ))
  else
    msg="$1"
  fi

  # 2. Print message
  if [ "$msg" ]; then
    printf "\n%*s%s\n" $pad "" "$msg"
    # 3. Underline
    for (( i=0; i<${#msg}; i++ )); do
      Log -ln "${2:-=}"
    done
    Log
  fi
}
export -f LogUnderline

#
# -------------------- Logging Verbosity ---------------------------------------
#

# Enable verbose logging
LogEnableVerbose() {
  if [[ ! $QUIET ]] && [[ ! $VERBOSE ]]; then
    declare -g VERBOSE=1
    LogVerbose "Verbose logging enabled"
  fi
}
export -f LogEnableVerbose

# Ask if verbose logging has been enabled
LogVerboseEnabled() {
  [[ $VERBOSE ]] && return 0 || return 1
}
export -f LogVerboseEnabled

# Enable debug & verbose level logging
LogEnableDebug() {
  if [[ ! $QUIET ]] && [[ ! $DEBUG ]]; then
    declare -g DEBUG=1
    LogEnableVerbose
    LogDebug "Debug logging enabled"
  fi
}
export -f LogEnableDebug

# Ask if debug logging has been enabled
LogDebugEnabled() {
  [[ $DEBUG ]] && return 0 || return 1
}
export -f LogDebugEnabled

# Disable any output to stdout. stderr and other types of logs remain active.
# Mutually exclusive with verbose and debug logging. If both specified, quiet wins.
LogEnableQuiet() {
  declare -g QUIET=1
  unset VERBOSE
  unset DEBUG
}
export -f LogEnableQuiet

# Ask if quiet mode has been enabled
LogQuietEnabled() {
  [[ $QUIET ]] && return 0 || return 1
}
export -f LogQuietEnabled

#
# -------------------- Parameter Parsing ---------------------------------------
#

# Prints the lines in the help screen for the built-in parameters.
#   If using LogTable for the other parameters, include the output of this 
#   function right along with the others.
# By default, all parameters are printed.
# + $1 - $n = (opt) [named param] "PARAMETER={0 | 1}" to disable/enable that parameter.
#             If a parameter is specified more than once, the last one wins.
# - stdout = The requested lines to include in your parameter description table
# Example: If you wanted to suppress the description of -q, the you would call this function like:
#   LogParamsHelp -q=0
#
LogParamsHelp() {
  declare -i v=1 vv=1 q=1
  
  for p in "$@"; do
    paramName=$(GetParamName "$p")
    enable=$(GetParamValue "$p")

    case $paramName in
      -v)
        v=$enable ;;
      -vv)
        vv=$enable ;;
      -q)
        q=$enable ;;
      *)
        LogError "Unknown parameter: $paramName"
        return 99 ;;
    esac
  done

  declare msg=""
  [ $v == 0 ] || msg+="\t-v\tVerbose output\n"
  [ $vv == 0 ] || msg+="\t-vv\tDebug mode (implies -v)\n"
  [ $q == 0 ] || msg+="\t-q\tQuiet: Suppresses all output (overrides -v and -vv)\n"

  Log "$msg"
}
export -f LogParamsHelp

#   Note: This function, called automatically, reads the parameters 
#     and takes appropriate action on them,
#     but it does not remove them from the parameter list ($@), 
#     so you may still need to ignore them to avoid interpeetting them as invalid.
#     To do that, compare them against the array LOGPARAMS.
#     You can drop it right into a case statement, like
#       case $param in
#         "${LOGPARAMS[*]}")
#           # ignore
#           ;;
#       esac
#     Note the use of * rather than @. That's important.

declare -axg LOGPARAMS=('-vv' '-v' '-q')
export LOGPARAMS

# Formats the CLI parameters handled by this script in the necessary format for use as a 'case' clause.
# This is necessary for client scripts that want to detect invalid flags 
#   or use the * match term to initialize stand-alone parameters.
# They need to know to ignore these so that they aren't throwing an error when someone passes in a -v
# Example Usage:
#   case $a in
#     *($(LogParamsCase))* )
#       : ;;    # Ignore
#   esac
# Note: This usage requires extended globs to be enabled

shopt -s extglob    # You can turn this off after parsing the command line if you need to

LogParamsCase() {
  caseStr="$(printf '%s | ' "${LOGPARAMS[*]}")"
  printf '%s' "${caseStr::-2}"
}
export -f LogParamsCase

_ParseCLI() {
  # Transparently parse certain reserved flags from CLI parameters
  for param in "$@"; do
    case "$param" in
      -vv)
        LogEnableDebug ;;
      -v) 
        LogEnableVerbose ;;
      -q)
        LogEnableQuiet ;;
    esac
  done
}

#
# -------------------- Pretty Colors ---------------------------------------
#

declare -Axgr COLOR=( \
  [BLACK]="\\033[0;30m" \
  [GRAY]="\\033[1;30m" \
  [PURPLE]="\\033[0;35m" \
  [BLUE]="\\033[0;34m" \
  [CYAN]="\\033[0;36m" \
  [RED]="\\033[0;31m" \
  [GREEN]="\\033[0;32m" \
  [LRED]="\\033[1;31m" \
  [LPURPLE]="\\033[1;35m" \
  [LGREEN]="\\033[1;32m" \
  [LBLUE]="\\033[1;34m" \
  [LCYAN]="\\033[1;36m" \
  [BROWN]="\\033[0;33m" \
  [YELLOW]="\\033[1;33m" \
  [LGRAY]="\\033[0;37m" \
  [NC]="\\033[0m" \
  [DEFAULT]="\\033[0m" \
  [NONE]="\\033[0m" \
  [WHITE]="\\033[1;37m" )
export COLOR

# Prints all of the available color names in their respective color.
# - stdout = a list of colored color names. One per line.
ShowColors() {
  for clr in "${!COLOR[@]}"; do
    if [[ "$1" == -u ]]; then
      [[ -n "$(echo "${COLOR[$clr]}" | grep ';')" ]] && LogColor $clr "$clr"
    else
      LogColor $clr "$clr"
    fi
  done
}
export -f ShowColors

# Corrects and validates color names against the supported set
# + $1 = The color name
# - retVal = Success if the color could be matched.
# - stdout = The corrected color name
ValidateColorName() {
  if [ -z "$1" ]; then
    printf "NC"
    return 99
  fi

  # Try to figure out what color the caller is trying to identify
  local colorName="${1^^}"
  colorName="$(echo "$colorName" | sed -E -e 's/LIGHT\s*/L/' -e 's/GREY/GRAY/' -e 's/CIAN/CYAN/')" 
  if [[ "${COLOR[$colorName]}" ]]; then
    printf "$colorName"
    return 0
  else
    printf "NC"
    return 1
  fi
}
export -f ValidateColorName

GetColorCode() {
#  LogDebugError "Getting color code for: $1"
  local _cName="$(ValidateColorName "$1")"
  [[ ! $? ]] && { printf "${COLOR[NC]}"; return 99; }
#  LogDebugError "Validated color name: $_cName"
  local _colorCode="${COLOR[$_cName]}"
#  LogDebugError -l "Returning color code: $_colorCode" 
  printf "%s" "$_colorCode"
}
export -f GetColorCode

# Returns your text ready to be displayed in the indicated color.
# This function must be called inline of a 'Log*' or 'printf "%b"'.
# If you want to easily color an entire line of text, use LogColor()
# + $1 = (optional) -e : Indicates that you need an extra escape character in order to force colors down sed's throat!
# + $2 = The desired text color. Value must exist within the set of keys of COLOR (i.e. ${!COLOR[@]})
# + $3 = The boring text that will soon be Fabyuloos!
# - stdout = Your new enhanced text experience. Works seamlessly with Log(). But if using echo, don't forget the -e !
ColorText() {
  # For backward-compatability reasons, 
  #   the extra escape flag can also be
  #   in the trailing position.
  local cName="$1" msg="$2"
  if [ "$3" ]; then
    local -r extraEsc='\'
    if [ "$1" == '-e' ]; then
      cName="$2"
      msg="$3"
    fi
  fi

  # Ensure that color is a valid choice
  local colorCode="$(GetColorCode "$cName")"
  if [ $? ]; then
    if [[ -n "$msg" ]]; then
      printf "%b" "${extraEsc}${colorCode}${msg}${extraEsc}${COLOR[NONE]}"
    else
      printf "%b" "$colorCode"
    fi
  else
    if LogDebugEnabled; then
      LogDebugError "Invalid color specified: $cName"
      ShowColors >&2
    fi
    printf "%b" "$msg"
    return 98
  fi
}
export -f ColorText

#
# ALL OF THE THINGS THAT ARE INVOKED AUTOMATICALLY SHALL APPEAR BENEATH THIS TEXT!
#

# We can't check whether we're being sourced as a condition to run
#   because we're always being sourced. 
# So, all we can do is not be harmful if we're being loaded for some other purpose

_ParseCLI "$@"
