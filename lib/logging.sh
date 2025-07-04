[[ -n "$__logging" ]] && return
__logging=1

source "${USERLIB:=$HOME/lib}/arrays.sh"
source "${USERLIB:=$HOME/lib}/read_stdin.sh"

#
# -------------------- Internal Use Only ---------------------------------------
#
_Log() {
  local _msg

  if [ "$2" ]; then
      [ "$2" == "--" ] && _msg="$(cat)" \
                       || _msg="$2"
  else
      [ "$1" == "--" ] && _msg="$(cat)" \
                       || _msg="$1"
  fi

  case "$1" in
    "")
      echo ;;
    --)
      echo -e "$_msg" ;;
    -lr)
      [ "$_msg" ] && printf "%${COLUMNS}s\n" "$_msg" || echo ;;
    -lrn)
      [ "$_msg" ] && printf "%${COLUMNS}s" "$_msg" ;;
    -ln)
      [ "$_msg" ] && printf "%s" "$_msg" ;;
    -l)
      [ "$_msg" ] && printf "%s\n" "$_msg" || echo ;;
    -n)
      [ "$_msg" ] && echo -e "$1" "$_msg" ;;
    *)
      echo -e "$_msg" ;;
  esac
  unset _msg
}

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

#
# -------------------- System Log / Journal ---------------------------------------
#

# Writes the specified message to the system log/journal
# + $1 = (optional) Parameters to pass to the logger command
# + $2 = The message to write or -- to send piped content
# + stdin = The message to write
# - journalctl = The message
Journal() {
  _Journal user.info "$1" "$2"
}
export -f Journal

# Writes the specified message to the system log/journal
# + $1 = (optional) Parameters to pass to the logger command
# + $2 = The message to write or -- to send piped content
# + stdin = The message to write
# - journalctl = The message
JournalError() {
  _Journal user.error "$1" "$2"
}
export -f JournalError

# Writes the specified message to the console and the system log
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = Ass and Pussy destructionThe message to write (supports escaped control characters) or -- to send piped content
# + stdin = The message to write (supports escaped control characters)
# + stdout = The message
# - journalctl = The message
LogTee() {
  Log "$1" "$2"
  Journal "$1" "$2"
  return $?
}
export -f LogTee

# Writes the specified message to the console and the system log
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters) or -- to send piped content
# + stdin = The message to write (supports escaped control characters)
# + stderr = The message
# - journalctl = The message
LogErrorTee() {
  LogError "$1" "$2"
  JournalError "$1" "$2"
  return $?
}
export -f LogErrorTee

#
# -------------------- Console Output ---------------------------------------
#

# Writes the specified message to the console
# Supports piped messages with or without other parameters when you specify --
# Calling Log with no parameters will generate a newline
# Escape sequences are interpreted by default unless you specify -l
# + $1 = (opt) parameters to apply to the log output
#        -- = Message is piped in
#        -n = Suppress newline
#        -l = Stop trying to be smart and output LITERALLY what I'm telling you!
#        -ln = Literal value with no newline
#        -lr = Literal and right-justified
#        -lrn = Literal and right-justified with no newline
# + $2 = The message to write or -- for stdin
# + stdin = The message to write
# - stdout = The message
Log() {
  [ "$(LogQuietEnabled)" ] && return 0
  _Log "$1" "$2"
  return $?
}
export -f Log

# Writes the specified message to stderr
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters) or -- to send piped content
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogError() {
  _Log "$1" "$2" >&2
}
export -f LogError

# Writes the specified message to the console if verbose logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# + $VERBOSE = Set to enable verbose logging
# - stdout = The message
LogVerbose() {
  [ "$(LogVerboseEnabled)" ] && Log "$1" "$2" 
}
export -f LogVerbose

# Writes the specified message to stderr if verbose logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogVerboseError() {
  [ "$(LogVerboseEnabled)" ] && LogError "$1" "$2"
}
export -f LogError

# Writes the specified message to the console if debug logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $DEBUG = Set to enable debug logging
# - stdout = The message
LogDebug() {
  [ "$(LogDebugEnabled)" ]  && Log "$1" "$2"
}
export -f LogDebug

# Writes the specified message to stderr if debug logging is enabled
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogDebugError() {
  [ "$(LogDebugEnabled)" ] && LogError "$1" "$2"
}
export -f LogError

#
# ------------------------ Prompts -------------------------------------------
#

# Prompts for input from the user
# + $1 = The message to display to the user.
# + $2 = The prompt type:
#         1 = freeform
#         2 = single-character selection
#         3 = integer
#         4 = phone number [not implemented]
#         5 = email [not implemented]
# + $3 = Input validation parameters
#         selection = Name of a defined array containing all valid selections. First = default
#         integer = MinValue-MaxValue
#         phone = Exact number of digits (including punctuation)
#         all others = Just enter a dash (-)
# + $4 = (optional) Timeout value (in seconds) [not implemented]
# - stdout = The selection
# - return = Success (0) or
#         1 = Input format was corrected, but none of the input data was lost.
#         2 = Input was truncated or otherwise some portion was lost to conform to validation requirements
#         3 = Input is invalid
#         99 = Method was called incorrectly
Prompt() {
  msg="$1"
  pType="$2"
  case $ptype in
    1) # freeform
      read -p "$msg " input; LogError
      echo "$input" ;;
    2) # single-digit selection
      local -n options="$3"
      [ "${#options[@]}" == 0 ] && return 99
      [ "${#options[0]}" != 1 ] && return 99
      local -a optArray=(${options[0]^^})
      for (( i=1; i<${#options[@]}; i++ )); do
        optArray+="$${options[$i],,}"
      done
      optStr="$(SerializeArray -d=/ "options")"
      read -n1 -p "$msg [$optStr]? " input; LogError 
      echo "$input" ;;
    3) # integer
      local minValue="$(echo "$3" | sed -E 's/([0-9]+)-[0-9]+/\1/')"
      local maxValue="$(echo "$3" | sed -E 's/[0-9]+-([0-9]+)/\1/')" 
      read -p "$msg " input; LogError
      if (( $p < $minValue )) || (( $p > $maxValue )); then
        LogError "Value entered $input does not fall within expected range $minValue-$maxValue"
        return 3
      fi
      echo "$input" ;;
    4) # phone number
      let numDigits=$3 ;;
    5) # email address
      ;;
    *)
      return 99 ;;
  esac
}

PromptVewrbose() {
  if [ "$(LogVerboseEnabled)" ]; then
    Prompt "$@"
  fi
}

PromptDebug() {
  if [ "$(LogDebugEnabled)" ]; then
    Prompt "$@"
  fi
}

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
  Log "$1" "$2" | FormatTable
}

# Writes the specified message formatted as a table to stderr
# Message is formatted as a table using tabs (\t) to denote columns.
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogTableError() {
  Log "$1" "$2" | FormatTable >&2
}

# Writes the specified message in bold face to stdout.
# Message is formatted as a table using tabs (\t) to denote columns.
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stdout = The message
LogHeader() {
  Log "$(Log "$1" "$2" | Header --)"
}

# Gives the appearance of the passed-in text being in bold face
# Whether this effect works or not will depend on the color pallete 
#   of your terminal emulator. If white and light gray look the same
#   then this function will accomplish nothing.
# + $1 = The header/title text
# + stdin = The header/title text (in leiu of $1)
# - stdout = Your new far-more-magnanimous text!
Header() {
  msg="$(Log "$1")"
  [ "$msg" ] && ColorText WHITE "$msg"
}

# Formats your tab-delimited text into a table
# + stdin = Your complete single or multi-line text
# - stdout = Your text now formatted into columns
FormatTable() {
  column -t -s $'\t'
}

# Writes the specified message in bold face to stderr
# Message is formatted as a table using tabs (\t) to denote columns.
# + $1 = (opt) parameters to apply to the echo command. -e is already applied.
# + $2 = The message to write (supports escaped control characters)
# + stdin = The message to write (supports escaped control characters)
# - stderr = The message
LogHeaderError() {
  LogError "$(Log "$1" "$2" | Header --)"
}

# Logs *exactly* what you pass in with no interpretation of anything
# + $1 = (opt) Parameter to control how the output is presented.
#        -n = Do not inject a newline after the message
# + $2 = The message to log
# - stdout = Your exact message
LogLiteral() {
  [ "$1" == '-n' ] && Log -ln "$2" \
                   || Log -l "$1"
}

# Print message right-justified in the console window
# + $1 = (opt) Parameter to control how the output is presented.
#        -n = Do not inject a newline after the message
# + $2 = The message to log
# - stdout = Your exact message, right-justified
LogRight() {
  [ "$1" == '-n' ] && Log -lrn "$2" \
                   || Log -lr "$1"
}

# Print message with an underline effect
# Output will consume 2 rows of display
# Line will be the same length as your text
# + $1 = Message
# + $2 = (opt) Character to use for the underline effect
# - stdout = Your exact message with a row of dashes on the subsequent line
LogUnderline() {
  msg="$(Log -l "$1")" # Pass it through any applicable filters or standard formatting
  if [ "$msg" ]; then
    Log
    Log -l "$msg"
    for (( i=0; i<${#msg}; i++ )); do
      Log -ln "${2:--}"
    done
    Log
  fi
}

#
# -------------------- Logging Verbosity ---------------------------------------
#

# Enable verbose logging
LogEnableVerbose() {
  if [ ! $QUIET ]; then
    declare -g VERBOSE=1
    LogVerbose "Verbose logging enabled"
  fi
}
export -f LogEnableVerbose

# Ask if verbose logging has been enabled
LogVerboseEnabled() {
  [ $VERBOSE ] && echo "Verbose logging is enabled"
}
export -f LogVerboseEnabled

# Enable debug & verbose level logging
LogEnableDebug() {
  if [ ! $QUIET ]; then
    declare -g DEBUG=1
    LogDebug "Debug logging enabled"
    LogEnableVerbose
  fi
}
export -f LogEnableDebug

# Ask if debug logging has been enabled
LogDebugEnabled() {
  [ $DEBUG ] && echo "Debug logging is enabled"
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
  [ $QUIET ] && echo -n "QuietEnabled"
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
  declare -r FNAME="LogParamsHelp()"
  declare -i h=1 v=1 vv=1 q=1
  
  for p in "$@"; do
    paramName=$(echo "$p" | cut -d= -f0)
    enable=$(echo "$p" | cut -d= -f1)

    case $paramName in
      -h)
        h=$enable ;;
      -v)
        v=$enable ;;
      -vv)
        vv=$enable ;;
      -q)
        q=$enable ;;
      *)
        LogError "$FNAME: Unknown parameter: $paramName"
        return 99 ;;
    esac
  done

  declare msg=""
#  [ $h == 0 ] || msg+="\t-h\tPrint this help page"
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
  echo -n "$(SerializeArray -d='|' -ds -dS LOGPARAMS)"
}

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

declare -Axg COLOR=( \
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
# There's no need to export COLOR, it's already marked global.

# Prints all of the available color names in their respective color.
# - stdout = a list of colored color names. One per line.
ShowColors() {
  for clr in "${!COLOR[@]}"; do
    Log "$(ColorText $clr $clr)";
  done | sort
}
export -f ShowColors

# Returns your text ready to be displayed in the indicated color.
# + $1 = (optional) -e : Indicates that you need an extra escape character in order to force colors down sed's throat!
# + $2 = The desired text color. Value must exist within the set of keys of COLOR (i.e. ${!COLOR[@]})
# + $3 = The boring text that will soon be Fabyuloos!
# - stdout = Your new enhanced text experience. Works seamlessly with Log(). But if using echo, don't forget the -e !
ColorText() {
  local -r FNAME="logging.ColorText()"

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

  if [ -z "$msg" ]; then
    LogVerboseError "$FNAME: Warning: Missing msg parameter. Returning empty string."
    echo -n ""
    return 99
  fi

  # Ensure that color is a valid choice
  local color="${COLOR["$cName"]}"
  if [ -z "$color" ]; then
    LogVerboseError "$FNAME: Warning: Invalid color specified: $cName"
    ShowColors
    echo -n "$msg"
    return 98
  fi

  echo -n "${extraEsc}${color}${msg}${extraEsc}${COLOR[NONE]}"
}
export -f ColorText

#
# ALL THINGS THAT ARE INVOKED AUTOMNATICALLY SHALL APPEAR BENEATH THIS TEXT!
#

# We can't check whether we're being sourced as a condition to run
#   becsause we're always being sourced. 
# So, all we can do is not be harmful if we're being loaded for saome other purpose

_ParseCLI "$@"
