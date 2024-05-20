# -------------------------------------------------------------------------
# Output utility functions
# -------------------------------------------------------------------------
function _tput() {
    if [[ $theme == "none" ]] || [[ -n ${NO_COLOR} ]]; then
        return
    fi
    tput "$@" 2> /dev/null
}

function mecho() { echo "$@" 1>&2; }

function mdebug() {
    if ! $debug; then
        return
    fi
    {
        _tput setaf 8 ## gray
        echo "DEBUG: $*"
        _tput sgr0    ## reset
    } 1>&2
}

function merror() {
    local info version
    {
        info="ucsf-vpn $(version)"
        version=$(openconnect_version 2> /dev/null)
        if [[ -n $version ]]; then
            info="$info, OpenConnect $version"
        else
            info="$info, OpenConnect version unknown"
        fi
        [[ -n $info ]] && info=" [$info]"
        _tput setaf 1 ## red
        echo "ERROR: $*$info"
        _tput sgr0    ## reset
    } 1>&2
    _exit 1
}

function mwarn() {
    {
        _tput setaf 3 ## yellow
        echo "WARNING: $*"
        _tput sgr0    ## reset
    } 1>&2
}

function minfo() {
    if ! $verbose; then
        return
    fi
    {
        _tput setaf 4 ## blue
        echo "INFO: $*"
        _tput sgr0    ## reset
    } 1>&2
}

# shellcheck disable=SC2317
function mok() {
    {
        _tput setaf 2 ## green
        echo "OK: $*"
        _tput sgr0    ## reset
    } 1>&2
}

function mdefunct() {
    {
        _tput setaf 1 ## red
        echo "DEFUNCT: $*"
        _tput sgr0    ## reset
        exit 1
    } 1>&2
}

function mnote() {
    {
        _tput setaf 11  ## bright yellow
        echo "NOTE: $*"
        _tput sgr0    ## reset
    } 1>&2
}

function _exit() {
    local -i value

    value=${1:-0}
    pii_cleanup
    mdebug "Exiting with exit code $value"
    exit $value
}
