#!/bin/bash

source "${USERLIB:-$HOME/lib}/general.sh"
declare -r APPNAME="script.template"

PrintHelp() {
  Log "<General Description>"
  Log
  Log "$(Header "Usage:") $APPNAME [FLAGS] INPUT1 INPUT2"
  Log
  Log "$(Header "FLAGS:")\t(Optional)"
  LogTable "$(LogParamsHelp -q=0)       # Print standard set of options, except -q
  \t-h\tPrint this help screen.
  \t-1\tFlag 1
  \t-2\tFlag 2"
  Log
  LogHeader "INPUT 1:"
  Log "\t\tLong description."
  Log
  Log "$(Header "INPUT 2:") Short description."
  Log
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

ParseCLI() {
  for p in $@; do
    case "$p" in
      $(LogParamsCase))  
        ;;        # Ignore these. They are handled for you
      "" | -h | ? | -? | --help)
        PrintHelp
        exit 0 ;;
      -1)
        ;;  # Flag 1 - This is just an example.
      -2)
        ;;  # Flag 2 - Do whatever you want with these... or delete them entirely.
      *)
        [ "$INPUT1" ] && INPUT2="$p" || INPUT1="$p" # If INPUT1 has a value already, assign this shit to INPUT2
    esac                                            # Otherwise, go on ahead and let INPUT1 have it
  done
}

Main() {
  ParseCLI

  # Do amazing shit!
}

# Protect your entry point from execution if this script is sourced rather than run normally
# As it definitely will be for a variety of reasons.
# Therefore, everything outside of this block can only be: 
#   * Functions
#   * Global variables & constants
#   * Sourcing of library scripts
#   * Veerification of required preconditions (e.g. dependent scripts/commands that are not in the library)
# I don't want to hear "But logging.sh runs code unconditionally!"
# Logging.sh was written by Ascended Bash Masters. It is perfect in every way... EVERY. WAY.
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
  Main
fi
