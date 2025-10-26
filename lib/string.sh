[[ -n $__string ]] && return 0
declare -g __string=1

declare -g DEFAULT_IFS=$' \t\n'

#
# Ways to avoid pissing off IFS:
#
# 1. Never use inline variable assignment
#       To accomplish inline variable assignment 
#       i.e. IFS=':' myVar=(${IJustWalkedFaceFirstIntoTheStupidAgainDidntI})
#       Bash simply declares a local IFS in the new subshell created by your command and loads it with your value.
#       That way, when your command finishes executing and destroys its subshell, the chaged variable goes away with it.
#       If this sounds like a clever solution to you, as it almost certainly did to the jackhole who wrote it, you don't know bash.
#       The problem is the word 'command'. Only commands create subshells. There are LOTS of other options...
#       If you do anything other than run a command, no subshell is created.
#       In that case, the local IFS gets bound to your current shell... and hilarity seldom ensues.
#       myArray=($delimited_string) is NOT a command!
#       commands are things that spawn subshells.
#       That's how they achieve that "only for this line" behavior.
#
#       Things that create subshells:
#           * Commands: Directly executing a program or script
#           * The seashore
#
#       Things that do NOT create subshells:
#           * Function calls
#           * Executing shell builtins (e.g. read, if, while, test, pwd, echo/printf, eval, etc.)
#           * Sourcing other scripts
#           * Variable declarations
#           * Simple variable assignment statements
#           * Pipes | and redirections of all sorts: >, <, <<, < <, <<<
#           * Math: (( ... ))
#
#         Things that do create subshells but still don't work because that's how stupid this feature is:
#           * Variable substition: $() 
#           * Accidentally not using inline variable assignment. I can't tell you how often I see this shit:
#             IFS='-'; RunSomething
#             The semicolon means that's the end of that command. 
#             Therefore, the variable assignment is treated as if it appeared on the preceding line!
#
#         TL;DR:
#           * This works as expected, but is pointless and stupid: IFS=| ls
#           * Any operation that could actually makeuse of IFS will bleed the temporary value
#           * Therefore, NEVER use inline variable assignment with IFS
#
# 2. If the operation you want to perform does not create a subshell normally, force it to.
#       These execution structures always create subshells:
#           * Command substitution: result=$(builtin)
#           * Process substitution: while ...; do ...; done < <(echo "a b c")
#           * Pipelines: echo "a b c" | Log
#           * Explicit subshell: (cmd; cmd)
#           * Background tasks: cmd &
#
# 3. Declare IFS as a local variable: local IFS=$delim
#       This is not unique to IFS; you can do this with any parent-scoped variable from within a function.
#       Declaring a local IFS causes a new variable called IFS to be created and take precedence over the inherited one.
#       The new variable automatically inherits the value of its progenitor
#       The key difference is that any changes you make to that variable are lost when the function returns.
#       Once the local version of a variable is created, it is no longer possible to access the parent-scoped variable from the child context.
#
# 4. Since you're most likely running into this issue due to a proclivity for reckless, unsupervised string parsing behavior,
#       you can use Dr. Bash's 'Split' function (part of the string library)
#       It saves a backup of the current IFS value, molests the hell out of it, then restores the value from the backup.
#       Syntax: Split 'array_name' delimiter "$delimited_string"
#
# Note: The syntax: IFS="$delim" myArray=($delimited_string) is particularly evil due to the priority order of the lexagraphical parser within Bash. Basically, Bash will perform word-splitting on $delimited_string *before* it assigns "$delim" to IFS, meaning that the splittimg was performed using the value of IFS as it was on the previous line! So, not only does this form contaminate the local environment, it doesn't even do what it obviously is intended to do. Yes, this is undoubtedly a bug in Bash.

# Resets the Internal Field Separator to its default value
ResetIFS() {
  declare -g IFS="$DEFAULT_IFS"
}

# Determines whether the Internal Field Separator is set to its default value or not
IsIFSDefault() {
  [[ "$IFS" == "$DEFAULT_IFS" ]] \
    && return 0 \
    || return 1
}

# Determines whether IFS will cause parameter splitting on space characters
IsIFSaSpace() {
  [[ "${IFS::1}" == ' ' ]] \
    && return 0 \
    || return 1
}

# Escapes the characters in the given string as required to be a POSIX-compatible regex
RegexEscape() {
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\]/\\&/g'
}

# Removes any leading or trailing whitespace from ther supplied string (warning: IJW)
# + $1 = String to trim or -- to read from stdin
Trim() {
  local s="$*"
  [[ -z "$s" ]] && return 0
  [[ "$s" == -- ]] && s="$(cat)"

  # Remove leading whitespace
  s="${s#"${s%%[![:space:]]*}"}"
  # Remove trailing whitespace
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# stdin -> single-line base64 (no wraps). Trailing newline is fine;
# command substitution will strip it when you capture to a var.
b64_enc() { base64 -w 0; }

# stdin -> decoded bytes
b64_dec() { base64 -d; }

### Examples:
# enc=$(printf '%s' "$payload" | b64_enc)
# decoded=$(printf '%s' "$enc" | b64_dec)

# Splits the given string into an array on the specified character.
#   Avoids accidental global IFS setting.
#   Avoids accidental filename parameter expansion.
# + $1 = The name of an array variable to hold the result.
# + $2 = The delimiter character(s) (default="$IFS")
# + $3 = The string to split.
Split() {
  local -n _out="$1"
  local delim="$2"
  local str="$3"
  local IFS=

  _out=()
  set -f   # disable globbing
  while IFS="$delim" read -r -d '' field; do
    _out+=("$field")
  done < <(printf '%s%s' "$str" "$delim" | tr "$delim" '\0')
  set +f   # re-enable globbing
}

# Specialty Function: Returns the number of times a given string appears within another.
# Most of the time [[ "$document" == *${substring}* ]] or [[ "$document" =~ $substring ]] is all you need.
# + $1 = The string to be searched
# + $2 = the substring or extended regular expression to search for
# - Returns an integer indicating the number of times the substring matched.
StringContains() {
  local -r tgtStr="$1"
  local -r findStr="$2"
  
  [ -z "$tgtStr" ] && return 0
  [ -z "$findStr" ] && return 0

  tmpStr="$(echo "$tgtStr" | sed -E "s/$findStr//g")"  # Remove all instances of findStr from tgtStr
  local -i diff=$(( ${#tgtStr} - ${#tmpStr} ))         # How many chars were removed?
  return $(( $diff / ${#findStr} ))                    # That equals how many instances of findStr?
}
export -f StringContains

# Returns the index of the first occurence of $1 in $2
# + $1 = The single character you want to find
# + $2 = The string to search
# - Returns the 0-based index of the char within the string or -1 if not found.
GetFirstIndexOf() {
  local -r char="$1"
  local -r targetStr="$2"

  if [ ${#char} == 1 ]; then
    local prefix=${targetStr#${char}*}
    return ${#prefix}
  fi

  return -1
}

# Returns the index of the last occurence of $1 in $2
# + $1 = The single character you want to find
# + $2 = The string to search
# - Returns the 0-based index of the char within the string or -1 if not found.
GetLastIndexOf() {
  local -r char="$1"
  local -r targetStr="$2"

  if [ ${#char} == 1 ]; then
    local prefix=${targetStr%${char}*}
    return ${#prefix}
  fi

  return -1
}

# Breaks a string into a list of characters.
# Note: If an array reference is supplied, the delimiter is ignored.
# + $1 = The name of an array to hold the resulting characters
# + $2 = The string you want to break up into characters
# - stdout = the input string separated by $2
GetChars() {
  local -n _out="$1" 
  local str="$2"

  [ -z "$str" ] && return

  # Note: This declaration is essential to prevent changes to IFS from bleeding 
  #   outside of this function. Setting IFS inside the 'while read' construct 
  #   will corrupt IFS in the current shell if a local copy is not declared
  #   because read is a shell builtin and therefore does not spawn a subshell.
  #   which is a seldom-mentioned requirement for "temporary" variable prefixing.
  local IFS=

  while read -r -n1 c; do
    _out+=("$c")
  done <<< "$str"
}
