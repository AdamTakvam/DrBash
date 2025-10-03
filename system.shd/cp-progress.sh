#!/bin/bash

source "$DRB_LIB/drbash.sh"

APPNAME="cp-progress"

Help() {
  Log "Copies the specified files with a simple 10-step progress indicator and optional 'time remaining' estimate."
  Log
  Log "$(Header "Usage:") $APPNAME [-t] FILE..."
  Log
  LogHeader "Parameters:"
  LogTable "\t-t\tInclude 'time remaining' estimate.
  \tFILE...\tOne of more filenames or glob patterns"
  Log
}

ShowCopyProgress() {
    local show_time=0
    local OPTIND opt

    # Parse options
    if [[ "$1" == -t ]]; then
      show_time=1
      shift
    fi

    # Now: source(s)... then destination
    local files=( "${@:1:$#-1}" )  # all but last arg
    local dest="${@: -1}"         # last arg
    local total=${#files[@]}
    local i bar progress pad
    local last_step=-1 start_time now elapsed est_total est_rem

    start_time=$(date +%s)
    echo -n "Copying   [..........]"

    for i in "${!files[@]}"; do
        local src="${files[i]}"
        cp "$src" "$dest" 2>/dev/null || {
            echo -ne "\rError copying: $src\n"
            continue
        }

        local step=$(( (i + 1) * 10 / total ))
        if [[ $step -ne $last_step ]]; then
            last_step=$step
            bar=$(printf "%-${step}s" | tr ' ' '#')
            pad=$(printf "%-$((10 - step))s")
            if (( show_time )); then
                now=$(date +%s)
                elapsed=$(( now - start_time ))
                est_total=$(( elapsed * total / (i + 1) ))
                est_rem=$(( est_total - elapsed ))
                printf -v eta "  ETA: %02d:%02d" $((est_rem / 60)) $((est_rem % 60))
            else
                eta=""
            fi
            echo -ne "\rCopying   [${bar// /#}${pad// /.}]$eta"
        fi
    done

    echo -e "\nDone."
}

case "$1" in
  ? | -h | --help | WTF)
    Help
    return 0 ;;
esac

ShowCopyProgress "$@"
