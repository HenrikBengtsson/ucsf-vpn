# -------------------------------------------------------------------------
# Sudo tools
# -------------------------------------------------------------------------
function assert_sudo() {
    local cmd

    cmd=$1

    if [[ -n $cmd ]]; then
        if [[ ${UCSF_TOOLS} == "true" ]]; then
            cmd=" ('ucsf vpn $cmd')"
        else
            cmd=" ('ucsf-vpn $cmd')"
        fi
    fi

    ## Should we ask for sudo permissions upfront?
    ## Note, this might add 'sudo: ... a password is required' event in
    ## /var/log/auth.log, which in turn might trigger an alert.
    if ! $presudo; then
        mwarn "If you are prompted '[sudo] password for $USER:' below, please enter the password for your account ('$USER') on your local computer ('$HOSTNAME')"
        return 0
    fi
    
    if sudo -v -n 2> /dev/null; then
        mdebug "'sudo' is already active"
        minfo "Administrative (\"sudo\") rights already establish"
        return
    fi
    mdebug "'sudo' is not active"

    {
        mwarn "This action$cmd requires administrative (\"sudo\") rights."
        _tput setaf 11  ## bright yellow
        sudo -v -p "Enter the password for your account ('$USER') on your local computer ('$HOSTNAME'): "
#        _tput setaf 15  ## bright white
        _tput sgr0      ## reset
    } 1>&2

    ## Assert success
    if ! sudo -v -n 2> /dev/null; then
        merror "Failed to establish 'sudo' access. Please check your password. It might also be that you do not have administrative rights on this machine."
    fi

    minfo "Administrative (\"sudo\") rights establish"
}
