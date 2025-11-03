# vim: filetype=bash

[[ -n $__help ]] && return 0
declare -g __help=1

# This script standdardizes the formatting of help documentation making 
#   it as easy as possible to write and maintain CLI help, man pages, and more!
# To avail yourself of this incredible asset, 
#   you just need to define the following variables and source this script:
#
# (Variables marked with * are mandatory)
# * APPNAME: The name of your script. 
# * HelpDescription: A brief overview of what your script does.
# - HelpContext: Summary of any prerequyisite knowledge the user must have or circumstantial preconditions that your script assumes.
# * HelpUsage: The names of any parameters that a user can/must provide. Be sure to follow the convention for clarity.
#       Convention: [OPTIONAL] MANDATORY <POSITIONAL> literal
# - HelpFlags:
# - HelpParamNames: The names of you parameters as they will appear on the Usage line
# - HelpParams: Associative array of parameter names and their respective descriptions

PrintHelp() {
  [ "$HelpDescription" ] && Log "$HelpDescription\n"
  [ "$HelpUsage" ] && Log -n "$(Header "Usage:") $APPNAME [Flags]"
  if [ "$HelpParams" ]; then
    for p in ${!HelpParams[@]}; do
      Log -n "$p "
    done
  fi
  Log "$(Header "FLAGS:")\t(Optional)"
  LogTable "$(LogParamsHelp)
  \t-h\tPrint this help screen.
  $HelpFlags\n"
  if [ $HelpParams ]; then 
    LogHeader "INPUT 1:"
    Log "\t\tLong description."
    Log
    Log "$(Header "INPUT 2:") Short description."
    Log
  fi
  # Optional sections include:
  #   - Concept: Explanation of the general concept or situation where one would want to run this
  #   - Dependencies: External dependencies (optional or required)
  #   - Requirements: Assumptions or preconditions this script assumes (e.g. Linux distros, minimum Bash version, etc)
  #   - Examples: Usage examples
  #   - Notes: Operational notes
  #   - Limitations: Warnings about limitations or incompatabilities
  #   - Configuration: Configuration file information
  #   - Modes: Different modes your script can run in (e.g. interactive vs unattended)
  #   - Help!: How to get help with an issue
  #   - Version: Version information
  #   - Copyright: Copyright or open source license
  #   - Author: Author's name and contact information
}
