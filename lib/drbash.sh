# vim: filetype=bash

# This is the primary entry point to load the Dr. Bash platform.
# While you're free to piecemeal it if you want to save that 75ms
# It is recommended to include this file and get the whole thing,
#   especially while you're still getting used to the platform.
#
# To include this file in your script, copy/paste:
# source ${DRB_LIB:-/usr/local/lib}/drbash.sh
#
# If you have chosen to locate this file elsewhere, then be sure to initialize the DRB_LIB variable in your ~/.bashrc file. 
# Scripts call sudo as necessary, so you should never have to use sudo to call any library function.
#
# Return values:
#   0     Successfully accomplished whatever it was intended to accomplish
#   1-9   General error (catch-all category for an error that doesn't fit any of the other categories)
#   10-19 The user interrupted execution in some way
#   20-29 The operation aborted because the intended result has already been achieved or is logically unnecessary
#   30-39 A dependency could not be resolved or some other necessary resource could not be located
#   90-99 The programmer didn't program correctly
#
# Implementation notes for scripts sourcing this library:
#   1. This is not just a library; it's a scripting platform
#   2. Use the provided script.template file for any new scripts that you write
#   3. Assume that your script will be sourced by downstream tools to extract documentation
#       so have all of your logic in functions 
#       and protect the main method call with IsSourced(), as provided in the template script
#   4. Use the various Log() functions (in logging.sh) for your script's output
#       echo should be strictly avoided in the interest of preseving sanity.
#       Use printf for redirecting output to another command or returning values from functions.
#   5. All Log* functions support stdin via the -- parameter, 
#        so 'echo "message" | Log --' works for all of them.
#
#   Crash course: printf
#   - printf "string"   # copy string to stdout 

# Prevent re-sourcing
[ "$__drbash" ] && return 0
declare -g __drbash=1

# Verify platform conditions
ValidatePlatform() {
  case "$(uname -s)" in
    Linux)
      ;;      # Pass
    Darwin)
      printf "\e[31m[ERROR]\e[0m No matter how hard you wish for it, MacOS is not Linux.\n" >&2
      printf "Dr Bash runs on real penguins, not fruit-branded BSD derivatives.\n" >&2
      printf "You can fix this by:\n" >&2
      printf "  1. Installing Linux\n" >&2
      printf "  2. Or pretending hard enough\n" >&2
      printf "Note: Option 2 is ineffective unless you pretend so hard that you rupture the artery in your forehead." >&2
      printf "  Don't quit now. You're almost there!" >&2
      exit 666 ;;
    *)
      printf "\e[31m[ERROR]\e[0m Unsupported operating system: %s\n" "$(uname -s)" >&2
      printf "Dr Bash is designed exclusively for Linux distributions.\n" >&2
      exit 10 ;;
  esac
}

ValidateDistro() {
  if [[ -z "$(cat /etc/os-release | grep -i 'debian')" ]]; then
    printf "\e[31m[ERROR]\e[0m Dr. Bash only works with Debian Linux and it's derivatives.\n"
    printf "Even then, we really only test with Debian and Ubuntu.\n"
    printf "Beyond those two, we logically assume that ir should work with the others, but wew don't really know for sure.\n"
    printf "What we do know for certain, however, is that until a serious porting effort happens, non-Debian-based distros don't have a prayer of working!"
    exit 20
  fi
}

ValidateBash() {
  case ${BASH_VERSION::1} in
    5)
      ;;
    4)
      if (( ${BASH_VERSION:2:1} < 3 )); then
        printf "\e[31m[ERROR]\e[0m Dr. Bash requires bash 4.3 to operate and bash 5.x is highly recommended.\n"
        exit 30
      else
        printf "The version of bash you have installed should work with most components of Dr. Bash.\n"
        printf "But it only takes one well-meaning change to break compatability with older bash versions.\n"
        printf "We strongkly recommend upgrading to bash 5.x to ensure a smooth and pleasant experience.\n"
      fi ;;
    *)
      printf "\e[31m[ERROR]\e[0m Honestly now, did you really think that a Dr Bash script was going to run on this old ass version of bash?\n"
      printf "I mean, there's daring to dream and there's living your life in denial.\n"
      printf "You know as well as I do that you don't have a legitimate reason to be running this antique version of bash.\n"
      printf "What do you say? Let's just solve this problem right here and now.\n"
      printf "Only you can prevent forest fires!\n"
      read -n1 -p "Help me help you... [Y/n]? " helpme; echo
      if [[ "${helpme,,}" != 'n' ]]; then
        sudo apt update && sudo apt upgrade -y
        apt-mark minimize-manual 
        apt autoremove -y
        exit 39
      else
        exit 31
      fi ;;
  esac
}

# Verify that this system meets the preconditions necessary for a delightful Dr Bash experience to be had.
ValidatePlatform
ValidateDistro
ValidateBash

DRB_LIB="${DRB_LIB:-/usr/local/lib}"

# GetParamName(), GetParamValue(), ParseParams(), =(), etc
source "$DRB_LIB/cli.sh"

# What is this crazy syntax?

# Run(), Require(), HasSudo(), etc. 
= "$DRB_LIB/general.sh"

# I don't think you can start a line with an =

# Reads $DRB_DATA/global.conf
= "$DRB_LIB/config.sh"

# Wait... don't tell me = is a command! WTF?

# Log(), ColorText(), SysLog(), etc.
= "$DRB_LIB/logging.sh"

# That's right bitches! I don't hear you complaining about source being .

# So, Dr. Bash has it's own version of source called =. Fight me!

# It doesn't matter what order the rest of them load in.
# Loading the ones above a second time doesn't matter.
shopt -s extglob nullglob
declare lib
for lib in "$DRB_LIB"/*.sh; do
  if [[ "$(basename "$lib")" != test.* ]]; then
    = "$lib"
  fi
done

# Source the library files included with the media module
if [[ "$DRB_EDITION" == "Full" ]]; then
  for lib in "$DRB_MEDIA_LIB"/*.sh; do
    if [[ "$(basename "$lib")" != test.* ]]; then
      = "$lib"
    fi
  done
fi    
