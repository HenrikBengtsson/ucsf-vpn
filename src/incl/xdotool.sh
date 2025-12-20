# -------------------------------------------------------------------------
# xdotool: command-line X11 automation tool
# -------------------------------------------------------------------------
function xdotool_version() {
    local out

    out=$(xdotool version 2> /dev/null)
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        echo "<PLEASE INSTALL>"
    else
        printf "%s\\n" "${out}" | sed -E 's/.* //'
    fi
}
