cdls () {
  cd "$1"
  ls
}

cdll () {
  cd "$1"
  ll
}

cdla () {
  cd "$1"
  la
}

cdlla () {
  cd "$1"
  lla
}

# List the dot-files in the specified directory
# $1 = path (default=CWD)
lsdot() {
  ls -a "$1" | cut -d ' ' -f2 |  grep '^[.]'
}

# Find out which subdirectories are hogging all of the disk space.
hog() {
  du -hc -d1 . | grep -vE '\s\.$' | sort -hr 
}

# Show the filesystem of all mounted volumes
shfs() {
  df -Th
}

#
# Check for potentially problematic filenames
#

# Checks whether the specified string (intended for filenames) contains special characters
# + $1 = The filename to check (use quotes!)
# + $2 = (opt) the literal value 'q' or '-q' to suppress stdout
# - stdout = A space-delimited list of the types of special characters found
#             The exact names of the special chars are in single-quotes in the retval description below
#             If none are found or $2 specified, then nothing
# - retval =  Bitfield reflecting the types of special characters detected in the supplied filename
#     Binary      Dec   Meaning                             Comment
#                0 0     $1 contains no special characters
#                1 1     $1 contains 'spaces'               Will we ever get to a point where this just works?
#               10 2     $1 contains 'newlines'             Just because you can doesn't mean that you should!
#              100 4     $1 contains 'nulls'                Masochistic
#             1000 8     $1 contains 'double-quotes'        Potential bash hazard
#            10000 16    $1 contains 'single-quotes'        Potential bash hazard
#           100000 32    $1 contains 'pipes'                Potential bash hazard
#          1000000 64    $1 contains 'colons'               Will get you into trouble on NTFS
#         10000000 128   $1 contains 'slashes'              The only character forbidden in Linux
#        100000000 256   $1 contains 'backslashes'          FAT, FAT32, and NTFS will never speak to you again
#       1000000000 512   $1 contains 'less-thans'           Potential bash hazard
#      10000000000 1024  $1 contains 'greater-thans'        Potential bash hazard
#     100000000000 2048  $1 contains 'asterisks'            Respect the glob
#    1000000000000 4096  $1 'ends_in_a_space_or_a_dot'      Windows interop
#   10000000000000 8192  $1 is just a 'single_dot'          What kind of twisted freak would...
#  100000000000000 16384 $1 is just 'two_dots'              ...the guy who implemented 'for' loops in Bash
# 1000000000000000 32768 $1 contains 'unprintable_ASCII'    (codes 0-31) Not implemented yet
FilenameContainsSpecialChars() {
  local file="$1"
  local -i retval=0
  local echoStr=''
  local -Ar CHARS=( \
    [' ']='spaces' \
    [$'\n']='newlines' \
    [$'\0']='nulls' \
    ['"']='double-quotes' \
    ["'"]='single-quotes' \
    ['|']='pipes' \
    [':']='colons' \
    ['/']='slashes' \
    ['\']='backslashes' \
    ['<']='less-thans' \
    ['>']='greater-thans' \
    ['*']='asterisks')  
  local -i currBitValue=1

  [ -z "$file" ] && return 0

  for c in "${!CHARS[@]}"; do
    if [[ "$file" =~ "$c" ]]; then
      echoStr=" ${CHARS["$c"]}"
      retVal+=$currBitValue
    fi
    currBitValue*=2
  done

  if [ "${file: -1}" == ' ' ] || [ "${file: -1}" == '.' ]; then
    echoStr=' ends_in_a_space_or_a_dot'
    retVal+=$currBitValue
  fi
  currBitValue*=2

  if [ "$file" == '.' ]; then
    echoStr=' single_dot'
    retVal+=$currBitValue
  fi
  currBitValue*=2

  if [ "$file" == '..' ]; then
    echoStr=' two_dots'
    retVal+=$currBitValue
  fi
  currBitValue*=2

  [ -z "$2" ] && echo -n "${echoStr:1}"
  return $retVal
}

### Example of how to use FilenameContainsSpecialChars by return code
#
# Checks whether the specified filename contains newlines 
# + $1 = The filename to check (use quotes!)
# + $2 = (opt) the literal value 'q' or '-q' to suppress stdout
# - stdout = "true" if $1 contains newlines and $2 not specified; otherwise nothing
# - retval =  0 if $1 contains newlines
#             1 if $1 does not contain newlines
FilenameContainsNewlines_Ex1() {
  FilenameContainsSpecialChars "$1" >/dev/null
  if (( $? & 2 )); then
    [ -z "$2" ] && echo -n "true"
    return 0
  else
    return 1
  fi
}

### Example of how to use FilenameContainsSpecialChars by standard output
#
# Checks whether the specified filename contains newlines 
# + $1 = The filename to check (use quotes!)
# + $2 = (opt) the literal value 'q' or '-q' to suppress stdout
# - stdout = "true" if $1 contains newlines and $2 not specified; otherwise nothing
# - retval =  0 if $1 contains newlines
FilenameContainsNewlines_Ex2() {
  specChars="$(FilenameContainsSpecialChars "$1")"
  if [ "$(echo "$specChars" | grep 'newlines' )" ]; then
    [ -z "$2" ] && echo -n "true"
    return 0
  else
    return 1
  fi
}

#
# Grepland
#

FindInFiles() {
  grep -EIHisnr --context=1 --devices=skip --exclude=*.mp4 --color=auto "$1" "${2:-*}"
}
alias search=FindInFiles

alias egrep='grep -e' # Extended regular expression matching
alias ngrep='grep -v' # iNverse matching grep
alias lgrep='grep -l' # Read match patterns from a fiLe (e.g. echo "stuff" | lgrep patterns.txt)
alias fgrep='grep -f' # Show only File names containing matching text
alias igrep='grep -i' # Case-Insensitive pattern matching

grep-help() {
  tabs 4
  echo "Forms of grep available:"
  echo -e "> egrep\tExtended regular expression matching"
  echo -e "> ngrep\tiNverse matching grep"
  echo -e "> lgrep\tread match patterns from a fiLe (e.g. echo "stuff" | lgrep patterns.txt)"
  echo -e "> fgrep\tshow only File names containing matching text"
  echo -e "> igrep\tcase-Insensitive pattern matching"
}
