# -------------------------------------------------------------------------
# CLI utility functions
# -------------------------------------------------------------------------
function version() {
    grep -E "^###[ ]*Version:[ ]*" "$0" | sed 's/###[ ]*Version:[ ]*//g'
}

function help() {
    local what
    local -a res

    what=$1

    ## Extract help section, which are all lines starting with '###'
    mapfile -t res < <(grep "^###" "$0" | grep -vE '^(####|### whatis: )' | cut -b 5-)

    ## Inject tool versions
    mapfile -t res < <(printf "%s\\n" "${res[@]}" | sed "s/{{gpclient_version}}/$(gpclient_version)/")
    mapfile -t res < <(printf "%s\\n" "${res[@]}" | sed "s/{{xdotool_version}}/$(xdotool_version)/")
    
    if [[ $what == "full" ]]; then
        mapfile -t res < <(printf "%s\\n" "${res[@]}" | sed '/^---/d')
    else
        mapfile -t res < <(printf "%s\\n" "${res[@]}" | sed '/^---/Q')
    fi

    if [[ ${UCSF_TOOLS} == "true" ]]; then
        mapfile -t res < <(printf "%s\\n" "${res[@]}" | sed -E 's/([^/])ucsf-vpn/\1ucsf vpn/')
    fi
    
    printf "%s\\n" "${res[@]}"
}
