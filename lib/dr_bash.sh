# This is the primary entry point to load the Dr. Bash platform.
# While you're free to piecemeal it if you want to save that 75ms
# It is recommended to include this file and get the whole thing,
#   especially while you're still getting used to the platform.
#
# To include in your script, copy/paste:
# source ${USERLIB:-/usr/local/lib}/dr_bash.sh
#
# If you have chosen to locate this file elsewhere, then be sure to initialize the USERLIB variable in your .bashrc file. 
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
#       echo should only be used for redirecting output to another command
#       or returning values from functions,
#   5. All Log* functions support stdin via the -- parameter, 
#        so 'echo "message" | Log --' works for all of them.

# Prevent re-sourcing
[ "$__drbash" ] && return 0
__drbash=1

declare -r DRBASH_VERSION=0.6

source "${USERLIB:-.}/arrays.sh"

# Log(), ColorText(), SysLog(), etc.
source "${USERLIB:-.}/logging.sh"

# Run(), Require(), HasSudo(), etc. 
source "${USERLIB:-.}/general.sh"

# Header(), Help(), etc.
source "${USERLIB:-.}/help.sh"

source "${USERLIB:-.}/run.sh"
