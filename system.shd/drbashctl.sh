#!/bin/bash

source "${DRB_LIB}/drbash.sh"

declare -r APPNAME='drbashctl'

Help() {
  tabs 4
  Log "This is the configuration tool for Dr. Bash. You can access the global configuration, add-on module configurations (e.g. media) and bespoke data files used to customize the operation of individual scripts."
  Log
  Log "$(Header "Usage:")\t$APPNAME [ ? | -h | --help | -v | --version ]
     \t$APPNAME MODULE [KEY]
     \t$APPNAME MODULE [[KEY] VALUE | EXPR]"
  Log
  LogHeader "MODULE"
  Log "Note: Specifying only the module name without any further parameters will open the relevant config file in your default text editor.\n"
  LogTable "\t? | -h | --help\tThat's right, access help however you want because I'm capable of writing OR logic! 
  \t\tI often wonder what the guy who wrote the 'Try using the --help flag' message justified that to himself.
  \t-v | --version\tFind out which version of Dr. Bash you got loaded up on this beotch.
  \tglobal\tSettings that affect all apps created on the Dr. Bash platform.
  \tglobal [KEY]\tIf KEY is omitted, then the global configuration file is opened in your default text editor.
  \t\tIf KEY is specified, the the value of that key is displayed.
  \tglobal KEY VALUE\tSets KEY to VALUE in the global configuration.
  .\b
  \t\t--- Media Module ---
  .\b
  \tmedia\tSettings that are specific to the apps in the 'media' module.
  \tmedia [KEY]\tIf KEY is omitted, then the media configuration file is opened in your default text editor.
  \t\tIf KEY is specified, the the value of that key is displayed.
  \tmedia KEY VALUE\tSets KEY to VALUE in the media module configuration.
  .\b
  \t\t--- Media Module: Rule Sets ---
  .\b
  \tupper [VALUE]\tWords that will be in all caps. (e.g. HD). Must be defined in capitals exactly as they should appear.
  \tlower [VALUE]\tWords that will never be capitalized (e.g. at). Must be defined in lower-case exactly as they should appear.
  \tfile-delete [EXPR]\tAll filenames that match EXPR will be marked for deletion (all such files must be approved before final deletion).
  \ttitle-omit [EXPR]\tAny text that matches EXPR will be removed from all movie titles.
  \ttagfix\tRules for normalizing tags.
  \t\t- A list of regex match expressions and replacement text. 
  \t\t- Data format is exactly how you define an associative array in Bash. 
  \t\t- Recommended: Only one match/replace pair per line. Just don't forget the backslashes at the end of lines!"
  Log
  LogHeader "Return Values"
  LogTable "\t-1\tOperation neither succeeded nor failed because you requested a change to a state that the system was already in.
  \t0\tOperation completed successfully.
  \t1\tThe specified MODULE does not exist.
  \t2\tA file access issue or pathing misconfiguration prevented access to config files.
  \t3\tThe specified KEY does not exist. This tool cannot be used to add new configuration keys.
  \t4\tThe specified KEY is read-only. Try setting it in your ~/.bashrc file instead.
  \t5\tThe specified VALUE was not valid for that KEY." 
}

# MODTYPES:
#   0 = keyvalue
#   1 = array 
#   2 = dictionary

declare -l module
declare -i modType
declare configFile
declare -u key
declare value

DoConfigOperation() {

  case "$modType" in
    0)                # keyvalue
      key="$1"
      value="$2" 
      if [[ -z "$key" ]]; then
        Log "Opening $configFile in your default text editor..."
        ${EDITOR:-vi} "$configFile"
      elif [[ -z "$value" ]]; then
        ConfigGet "$key"
      else
        ConfigSet "$key" "$value"
      fi ;;
    1)
      value="$1" 
      if [[ -n "$value" ]]; then
        # Read the file into an array, add the new item, sort the array, print it to the console, and rewrite the file
        Split list $'\n' "$(cat "$configFile")"                   # Read the file contents into an array/list
        if ! ArrayContains list -v="$value" -Iq; then             # Perform a case-sensitive literal-value search
          list+=("$value")                                        # Add the new entry to the list
          printf "%s\n" "${list[@]}" | sort | tee "$configFile"   # Resort the list, save it, and display it
        else
          Log "The $module module already contains an entry for $value."
        fi
      else
        Log "Opening $configFile in your default text editor..."
        ${EDITOR:-vi} "$configFile"
      fi ;;
    2)
      Log "Opening $configFile in your default text editor..."
      ${EDITOR:-vi} "$configFile" ;;
  esac
}

AccessConfig() {  
  module="$1"; shift

  LogDebug "module=$module | newEntry=$_newEntry"

  case "$module" in
    g*)
      modType=0
      configFile="$(GlobalConfigFile)" ;;
    m*)
      modType=0
      configFile="$(MediaConfigFile)" ;; 
    u* | abbr)
      modType=1
      configFile="$FILE_ABBR" ;;
    l* | filler)
      modType=1
      configFile="$FILE_FILLER" ;;
    ti* | patterns)
      modType=1
      configFile="$FILE_PATTERNS" ;;
    f* | delete)
      modType=1
      configFile="$FILE_DELETE" ;;
    ta*)
      modType=2
      configFile="$FILE_TAGS" ;;
    -v | --version)
      GetDrBashVersion
      return 0 ;;
    "" | ? | -h | --help)
      Help
      return 0 ;;
    *)
      LogError "Unrecognized module: $module"
      Help
      return 1 ;;
  esac

  DoConfigOperation "$@"
}

IsSourced || AccessConfig "$@"
