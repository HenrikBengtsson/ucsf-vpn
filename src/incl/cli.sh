# -------------------------------------------------------------------------
# CLI utility functions
# -------------------------------------------------------------------------
function version() {
    grep -E "^###[ ]*Version:[ ]*" "$0" | sed 's/###[ ]*Version:[ ]*//g'
}

function help() {
    local what res

    what=$1
    res=$(grep "^###" "$0" | grep -vE '^(####|### whatis: )' | cut -b 5- | sed "s/{{pulsesvc_version}}/$(pulsesvc_version)/" | sed "s/{{openconnect_version}}/$(openconnect_version)/")

    if [[ $what == "full" ]]; then
        res=$(echo "$res" | sed '/^---/d')
    else
        res=$(echo "$res" | sed '/^---/Q')
    fi

    if [[ ${UCSF_TOOLS} == "true" ]]; then
        res=$(printf "%s\\n" "${res[@]}" | sed -E 's/([^/])ucsf-vpn/\1ucsf vpn/')
    fi
    printf "%s\\n" "${res[@]}"
}
