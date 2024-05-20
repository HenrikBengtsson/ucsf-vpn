# -------------------------------------------------------------------------
# OpenConnect
# -------------------------------------------------------------------------
function openconnect_version() {
    local res

    res=$(openconnect --version 2> /dev/null)
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        echo "<PLEASE INSTALL>"
    else
        printf "%s\\n" "${res[@]}" | grep -F "version" | sed -E 's/.*v//'
    fi
}

function find_vpnc-script() {
    local file
    file=$(openconnect --help | grep -E "vpnc-script" | sed 's/[^"]*"//' | sed 's/".*//')
    if [[ -z "${file}" ]]; then
        merror "Failed to locate the default 'vpnc-script' script. It appears that openconnect --help does not specify it"
    fi
    echo "${file}"
}

function find_hooks_dir() {
    local file dir
    find_vpnc-script > /dev/null
    file=$(find_vpnc-script)
    dir=$(grep -E "^HOOKS_DIR=" "${file}" | sed 's/[^=]*=//' | sed 's/[[:blank:]]$//')
    echo "${dir}"
}


function install_vpnc() {
    local action file filename dest hooks_dir dir path
    action=${1:-install}

    mdebug "install_vpnc() ..."
    mdebug " - action: ${action}"

    ## Locate hooks directory
    find_vpnc-script > /dev/null
    hooks_dir=$(find_hooks_dir)
    mdebug " - hooks folder: ${hooks_dir}"

    filename="ucsf-vpn-flavors.sh"

    ## Is ucsf-vpn hook script already installed?
    dest="${hooks_dir}/${filename}"
    if [[ $action == "check" ]] && [[ ! -f "${dest}" ]]; then
        return 1
    fi
    
    if $force || [[ ! -f "${dest}" ]]; then
        file="$(mktemp -d)/${filename}"
        ucsf-vpn-flavors_code > "${file}"
        mdebug " - template: ${file}"
        assert_sudo "install-vpnc"

        ## Create hooks folder, if missing
        if [[ ! -d "${hooks_dir}" ]]; then
            sudo mkdir -p "${hooks_dir}"
            [[ -d "${hooks_dir}" ]] || merror "Failed to create directory: ${hooks_dir}"
        fi
    
        sudo cp "${file}" "${dest}"
        sudo chmod ugo+r "${dest}"
        [[ -f "${dest}" ]] || merror "Failed to create file: ${dest}"
        mok "Generic hook script added: ${dest}"
        if [[ -f "${file}" ]]; then
           rm "${file}"
        fi
    else
        minfo "Generic hook script already exists: ${dest}"
    fi

    ## Install symbolic links to ucsf-vpn hook script, if missing
    for dir in pre-init connect post-connect disconnect post-disconnect attempt-reconnect post-attempt-reconnect reconnect; do
        path=${hooks_dir}/${dir}.d
        dest="${path}/${filename}"
        if [[ $action == "check" ]] && [[ ! -L "${dest}" ]]; then
            return 1
        fi
        if $force || [[ ! -L "${dest}" ]]; then
            assert_sudo "install-vpnc"
            sudo mkdir -p "${path}"
            [[ -d "${path}" ]] || merror "Failed to create directory: ${path}"
            sudo ln -fs "${hooks_dir}/${filename}" "${dest}"
            [[ -L "${dest}" ]] || merror "Failed to create symbol link: ${dest} -> ${hooks_dir}/${filename}"
            mok "Symbolic link added: ${dest} -> ${hooks_dir}/${filename}"
        else
            minfo "Symbolic link already exists: ${dest} -> ${hooks_dir}/${filename}"
        fi
    done

    mdebug "install_vpnc() ... done"
    
    return 0
}

function openconnect_pid() {
    local -i pid

    ## Is there a PID file?
    if [[ ! -f "$pid_file" ]]; then
        mdebug "PID file does not exists: $pid_file"
        echo "-1"
        return
    fi

    mdebug "PID file exists: $pid_file"
    pid=$(cat "$pid_file")
    mdebug "PID recorded in file: $pid"

    ## Is the process still running?
    if ps -p $pid > /dev/null; then
        mdebug "Process is running: $pid"
        echo $pid
        return
    fi

    ## Remove stray PID file
    rm "$pid_file"
    mwarn "Removed stray PID file with non-existing process (PID=$pid): $pid_file"
    echo -1
}

function openconnect_flavor() {
    local res
    
    ## Is there a PID file?
    if [[ ! -f "${flavor_file}" ]]; then
        mwarn "Flavor file does not exists: ${flavor_file}"
        echo "<unknown>"
        return
    fi
    mdebug "Flavor file exists: ${flavor_file}"
    res=$(cat "${flavor_file}")
    if [[ -z ${res} ]]; then
        res="default"
    fi
    echo "${res}"
}


function prompt_yesno() {
    local prompt answer
    
    prompt=${1:?}

    mdebug "PROMPT: Asking user for yes-no input:"
    while true; do
        {
            _tput setaf 11  ## bright yellow
            printf "%s [Y/n]: " "${prompt}"
            _tput setaf 15  ## bright white
            read -r answer
            _tput sgr0      ## reset
        } 1>&2
        
        ## Default?
        if [[ ${answer} == "" ]]; then
            return 0
        fi

        ## yes or no?
        answer=${answer/ /}
        answer=$(tr '[:upper:]' '[:lower:]' <<< "${answer}")
        mdebug "- answer=${answer}"
        if [[ ${answer} == "yes" ]] || [[ ${answer} == "y" ]]; then
            return 0
        elif [[ ${answer} == "no" ]] || [[ ${answer} == "n" ]]; then
            return 1
        fi                 
    done
}


function openconnect_start() {
    local two_pwds openconnect_log_file log_file main_reason reason post_reason
    local -a opts
    local -i pid

    mdebug "openconnect_start() ..."

    pid=$(openconnect_pid)
    if [[ $pid != -1 ]]; then
        if [[ ! $force ]]; then
            merror "A VPN process ('openconnect' PID $pid) is already running."
        fi
    fi

    if ! $force; then
        if [[ $validate == *pid* ]] && [[ $(openconnect_pid) != -1 ]]; then
           mwarn "Skipping - already connected to the VPN"
           return
        elif [[ $validate == *ipinfo* ]] && is_connected; then
           mwarn "Skipping - already connected to the VPN"
           return
        fi
    fi

    ## Assert that OpenConnect is not already running
    if [[ -f "$pid_file" ]]; then
        merror "Hmm, this might be a bug. Do you already have an active VPN connection? (Detected PID file '$pid_file'; if incorrect, remove with 'sudo rm $pid_file')"
    fi

    if ! is_online; then
        merror "Internet connection is not working"
    fi

    minfo "Preparing to connect to VPN server '$server'"

    if [[ -n ${flavor} ]]; then
        ## Are vpnc generic hook scripts installed?
        if ! install_vpnc "check"; then
            if prompt_yesno "Do you want to install required ucsf-vpn hook scripts?"; then
                install_vpnc "install"
            else
                merror "Generic ucsf-vpn hook scripts not installed. To install manually, call 'ucsf vpn install-vpnc'"
            fi
        fi
        ## Assert that --flavor=<flavor> exists, if specified
        flavor_home > /dev/null
    fi
    
    assert_sudo "start"

    ## Load user credentials from file?
    source_netrc

    ## Prompt for username and password, if missing
    prompt_user "${user}"
    prompt_pwd "${pwd}"

    ## Prompt for 2FA token?
    if [[ "$realm" == "Dual-Factor Pulse Clients" ]]; then
        ## Prompt for one-time token, if requested
        prompt_token "${token}"
    fi

    ## openconnect options
    opts=()
    opts+=("${extras[@]}")

    ## VPN protocol
    if [[ "$protocol" == "juniper" ]]; then
        opts+=("--juniper" "${url}")
    else
        opts+=("--protocol=${protocol}" "${url}")
    fi
    
    opts+=("--background")

    if [[ -n $user ]]; then
        opts+=("--user=$user")
    fi
    if [[ -n $pwd ]]; then
        opts+=("--passwd-on-stdin")
    fi

    opts+=("--pid-file=$pid_file")

    if ! $debug; then
        opts+=("--quiet")
    fi

    mdebug "call: $call"
    mdebug "user: $user"
    if [[ -n $pwd ]]; then
        mdebug "pwd: <hidden>"
    else
        mdebug "pwd: <not specified>"
    fi
    if [[ -n $token ]]; then
        if [[ $token == "prompt" ]]; then
            mdebug "token: <prompt>"
        elif [[ $token == "push" || $token =~ ^(phone|sms|text)[1-9]*$ ]]; then
            mdebug "token: $token"
        else
            mdebug "token: <hidden>"
        fi
    else
        mdebug "token: <not specified>"
    fi
    mdebug "opts: [n=${#opts[@]}] ${opts[*]}"
    mdebug "call: sudo UCSF_VPN_VERSION=$(version) UCSF_VPN_FLAVOR=$(flavor_home) UCSF_VPN_LOGFILE=$(logfile) openconnect ${opts[*]} --authgroup=\"$realm\""

    if [[ $token == "push" ]]; then
         mnote "Open the Duo Mobile app on your smartphone or tablet to confirm ..."
    elif [[ $token =~ ^phone[1-9]*$ ]]; then
         mnote "Be prepared to answer your phone to confirm ..."
    elif [[ $token =~ ^(sms|text)[1-9]*$ ]]; then
         merror "Sending tokens via SMS is not supported by the OpenConnect interface"
    fi

    minfo "Connecting to VPN server '${server}'"

    if $dryrun; then
        _exit 0
    fi

    log_file="$(logfile)"
    openconnect_log_file="$(openconnect_logfile)"
    rm "${log_file}"
    log "openconnect_start() ..."
    
    ## Record IP routing table before connecting to the VPN
    ip route show > "${ip_route_novpn_file}"

    log "ip route show:"
    ip route show >> "${log_file}"

    if [[ -n $pwd && -n $token ]]; then
        case "${UCSF_VPN_TWO_PWDS:-password-token}" in
            "password-token")
                two_pwds="$pwd\n$token\n"
                ;;
            "token-password")
                two_pwds="$token\n$pwd\n"
                ;;
            *)
                merror "Unknown value of UCSF_VPN_TWO_PWDS: '$UCSF_VPN_TWO_PWDS'"
                ;;
        esac
        # shellcheck disable=SC2086
        sudo echo -e "$two_pwds" | sudo UCSF_VPN_VERSION="$(version)" UCSF_VPN_FLAVOR="$(flavor_home)" UCSF_VPN_LOGFILE="$(logfile)" openconnect "${opts[@]}" --authgroup="$realm" 2> "${openconnect_log_file}" 1> "${openconnect_log_file}"
    else
        # shellcheck disable=SC2086
        sudo UCSF_VPN_VERSION="$(version)" UCSF_VPN_FLAVOR="$(flavor_home)" UCSF_VPN_LOGFILE="$(logfile)" openconnect "${opts[@]}" --authgroup="$realm" 2> "${openconnect_log_file}" 1> "${openconnect_log_file}"
    fi

    ## Update IP-info file
    pii_file=$(make_pii_file)

    pid=$(openconnect_pid)
    mdebug "pid=$pid"
    if [[ $pid == -1 ]]; then
        cat "${openconnect_log_file}"

        ## Report on ping for VPN server
        if ! is_online "$server"; then
            main_reason="Most likely reason: The VPN server ($server) does not respond to ping; check your internet connection."
        else
            post_reason="Miscellaneous: The VPN server ($server) responds to ping"
        fi

        ## Post-mortem analysis of the standard error.
        ## (a) When the wrong username or password is entered, we will get:
        ##       username:password:
        ##       fgets (stdin): Inappropriate ioctl for device
        ## (b) When the username and password is correct but the wrong token
        ##     is provided, or user declines, we will get:
        ##       password#2:
        ##       username:fgets (stdin): Resource temporarily unavailable

        ## Was the wrong credentials given?
        if grep -q -F "username:password" "${openconnect_log_file}"; then
            reason="Incorrect username or password"
            reason="${reason}. You can test your credentials via the Web VPN at https://${UCSF_WEB_VPN_SERVER:-remote-vpn01.ucsf.edu}/"
        elif grep -q -F "Inappropriate ioctl for device" "${openconnect_log_file}"; then
            reason="Incorrect username or password"
            reason="${reason}. You can test your credentials via the Web VPN at https://${UCSF_WEB_VPN_SERVER:-remote-vpn01.ucsf.edu}/"
        elif grep -q -E "password#2" "${openconnect_log_file}"; then
            reason="2FA token not accepted"
        elif grep -q -iF "Unknown VPN protocol" "${openconnect_log_file}"; then
            reason="Unknown VPN protocol (option --protocol=<ptl>)"
        else
            reason="Check your username, password, and token"
            reason="${reason}. You can test your credentials via the Web VPN at https://${UCSF_WEB_VPN_SERVER:-remote-vpn01.ucsf.edu}/"
        fi
        
        if [[ -n "${main_reason}" ]]; then
            reason="${main_reason} Possible other reason: ${reason}"
        else
            reason="Likely reason: ${reason}"
        fi
        reason="Failed to connect to VPN server. ${reason}"
        if [[ -n "${post_reason}" ]]; then
            reason="${reason}. ${post_reason}"
        fi
        merror "${reason}"
    fi

    ## Wait for VPN tunnel to appear in IP routing table
    wait_for_ip_route_tunnel
    
    ## Wait for IP routing table to stabilize
    wait_for_ip_route

    ## Record IP routing table after having connected to the VPN
    ip route show > "${ip_route_vpn_file}"

    default_route_after=$(grep -E '^default[[:space:]].*tun' "${ip_route_vpn_file}" | sed 's/default //' | sed -E 's/ +$//')
    mdebug "Default IP routing changed to: ${default_route_after}"
    
    if $debug; then
        mdebug "Changes made to the IP routing table:"
        {
            _tput setaf 8 ## gray
            diff -u -w "${ip_route_novpn_file}" "${ip_route_vpn_file}"
            _tput sgr0    ## reset
        } 1>&2
    fi

    if $verbose; then
      default_route_before=$(grep -E '^default[[:space:]]' "${ip_route_novpn_file}" | sed 's/default //' | sed -E 's/ +$//')
      minfo "Default IP routing was changed from '${default_route_before}' to '${default_route_after}'"
    fi

    log "record flavor"
    echo "$(flavor_home)" > "${flavor_file}"

    log "openconnect_start() ... done"
    
    minfo "Connected to VPN server"
}

function openconnect_stop() {
    local kill_timeout
    local -i kk pid

    mdebug "openconnect_stop() ..."

    log "openconnect_stop() ..."
    
    pid=$(openconnect_pid)
    if [[ $pid == -1 ]]; then
        mwarn "Could not detect a VPN ('openconnect') process. Skipping."
        return
#        merror "Failed to located a VPN ('openconnect') process. Are you really connected by VPN? If so, you could manually kill *all* OpenConnect processes by calling 'sudo pkill -INT openconnect'. CAREFUL!"
    fi

    minfo "Disconnecting from VPN server"

    assert_sudo "stop"

    ## Record IP routing table while still connected to the VPN
    ip route show > "${ip_route_vpn_file}"
    
    ## Signal SIGINT to terminate OpenConnect. If the first one fails,
    ## try another one
    # shellcheck disable=SC2034
    for kk in {1..2}; do
        ## From 'man openconnect': SIGINT performs a clean shutdown by logging the
        ## session off, disconnecting from the gateway, and running the vpnc-script
        ## to restore the network configuration.
        mdebug "Killing OpenConnect process: sudo kill -s INT \"$pid\" 2> /dev/null"
        log "- sudo kill -s INT $pid"
        sudo kill -s INT $pid 2> /dev/null
    
         ## Wait for process to terminate
        kill_timeout=10
        timeout "$kill_timeout" tail --pid=$pid -f /dev/null
    
        ## Was the process terminated?
        if ! ps -p $pid > /dev/null; then
            break
        fi
    done

    ## Update IP-info file
    pii_file=$(make_pii_file)

    ## Assert that the process was terminated
    if ps -p $pid > /dev/null; then
        merror "Failed to terminate VPN process ('openconnect' with PID $pid). You could manually kill *all* OpenConnect processes by calling 'sudo pkill -INT openconnect'. CAREFUL!"
    fi

    ## OpenConnect should remove PID file when terminated properly,
    ## but if not, let us remove it here
    if [[ -f "$pid_file" ]]; then
        rm -f "$pid_file"
        mwarn "OpenConnect PID file removed manually: $pid_file"
    fi

    ## Wait for IP routing table to stabilize
    wait_for_ip_route
    
    ## Record IP routing table after being disconnected from the VPN
    ip route show > "${ip_route_novpn_file}"
    
    default_route_after=$(grep -E '^default[[:space:]]' "${ip_route_novpn_file}" | sed 's/default //' | sed -E 's/ +$//')
    mdebug "Default IP routing changed to: ${default_route_after}"

    
    if $debug; then
        mdebug "Changes made to the IP routing table:"
        {
            _tput setaf 8 ## gray
            diff -u -w "${ip_route_vpn_file}" "${ip_route_novpn_file}"
            _tput sgr0    ## reset
        } 1>&2
    fi
    
    if $verbose; then
      default_route_before=$(grep -E '^default[[:space:]].*tun' "${ip_route_vpn_file}" | sed 's/default //' | sed -E 's/ +$//')
      minfo "Default IP routing was changed from '${default_route_before}' to '${default_route_after}'"
    fi

    log "openconnect_stop() ... done"

    minfo "Disconnected from VPN server"
}


function openconnect_reconnect() {
    local kill_timeout
    local -i kk pid

    mdebug "openconnect_reconnect() ..."

    log "openconnect_reconnect() ..."
    
    pid=$(openconnect_pid)
    if [[ $pid == -1 ]]; then
        mwarn "Could not detect a VPN ('openconnect') process. Skipping."
        return
    fi

    minfo "Reconnecting to VPN server"

    assert_sudo "stop"

    ## From 'man openconnect': SIGUSR2 forces an immediate disconnection and
    ## reconnection; this can be used to quickly recover from LAN IP address
    ## changes.
    mdebug "sudo kill -s USR2 $pid"
    log "- sudo kill -s USR2 $pid"
    sudo kill -s USR2 $pid 2> /dev/null

    status "connected"

    log "openconnect_reconnect() ... done"

    minfo "Reconnected to VPN server"
}
