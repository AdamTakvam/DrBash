#!/bin/bash

set -o pipefail

declare APPNAME='bash-runner'
declare RUNNER_PATH='/usr/local/bash-chooser/'

WriteDefaultVersion() {
  local currVersion="$(bash --version | awk '/^GNU bash/ { print $4 }' | awk -F. '{ print $1"."$2 }')"
  [[ -z "$currVersion" ]] && return 1

  local invokingScript="${BASH_SOURCE[-1]}"
  [[ "$invokingScript" == "$BASH_SOURCE[0]" ]] && return 2

  local -i foundScript=0
  # If $invokingScript doesn't resolve to a file
  if [[ ! -f "$invokingScript" ]]; then
    # Then search the path for it
    local IFS=:
    for path in $PATH; do
      if [[ -f "$path/$invokingScript" ]]; then
        invokingScript="$path/$invokingScript"
        foundScript=1
        break
      fi
    done
  fi

  (( $foundScript )) || return 3

  # Edit the script in place and inject the version number into it
  sed -Ei 's/(#!.*$APPNAME)/\1 $currVersion/' "$invokingScript"
  
  printf '%s' "$currVersion"
  return 0
}

declare bash_version="$1"
if [[ -z "$bash_version" ]]; then
  bash_version="$(WriteDefaultVersion)"
  if [[ ! $? ]]; then
    printf '%s\n' "$APPNAME: Error: Failed to write version number into calling script (code = $?)"
    printf '%s\n' "$APPNAME: Simple fix: Specify the bash version your script was last tested with on your shebang line."
    return 1
  fi
fi

# Check if the specified version is installed.
# Note: We only discriminate major and minor release numbers
#   The caller will run the last release build for that major.minor version.
dir=$RUNNER_PATH/bash-$bash_version
if [[ ! -d "$dir" ]]; then
  # Download the installation package
  mkdir -p "$RUNNER_PATH/bash-$bash_version"
  cd "$RUNNER_PATH/bash-$bash_version"
  
  # TODO: Figure out the package version scheme
  build=""                                  # e.g. 2ubuntu3.4
  pgkVersion=$bashversion-$build            # e.g. 5.1-2ubuntu3.4 
  apt download bash=$pkgVersion
  arch="amd64"                              # TODO: Get actual arch value
  pkgFile="bash_$pkgVersion_$arch.deb"

  # Extract to target directory
  dpkg-deb -x "$pkgFile" .
fi



