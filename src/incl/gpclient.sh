# -------------------------------------------------------------------------
# gplient: The GlobalProtect VPN client
# -------------------------------------------------------------------------
function gpclient_version() {
    local res

    res=$(gpclient --version 2> /dev/null)
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        echo "<PLEASE INSTALL>"
    else
        printf "%s\\n" "${res[@]}" | sed -E 's/^gpclient +//' | sed -E 's/ .*//'
    fi
}

function gpclient_pid() {
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

## sudo gpclient --fix-openssl connect --as-gateway gp-ucsf.ucsf.edu
function gpclient_start() {
    local gpclient_pid gpclient_log_file log_file main_reason reason post_reason
    local -a opts
    local -i pid

    mdebug "gpclient_start() ..."

    pid=$(gpclient_pid)
    if [[ $pid != -1 ]]; then
        if [[ ! $force ]]; then
            merror "A VPN process ('gpclient' PID $pid) is already running."
        fi
    fi

    if ! $force; then
        if [[ $validate == *pid* ]] && [[ $(gpclient_pid) != -1 ]]; then
           mwarn "Skipping - already connected to the VPN"
           return
        elif [[ $validate == *ipinfo* ]] && is_connected; then
           mwarn "Skipping - already connected to the VPN"
           return
        fi
    fi

    ## Assert that gpclient is not already running
    if [[ -f "$pid_file" ]]; then
        merror "Hmm, this might be a bug. Do you already have an active VPN connection? (Detected PID file '$pid_file'; if incorrect, remove with 'sudo rm $pid_file')"
    fi

    if ! is_online; then
        merror "Internet connection is not working"
    fi

    minfo "Preparing to connect to VPN server '${server}'"

    assert_sudo "start"

    ## Load user credentials from file?
    source_netrc

    ## Prompt for username and password, if missing
    prompt_user "${user}"
    prompt_pwd "${pwd}"

    ## gpclient options
    opts=()
    opts+=("${extras[@]}")

    opts+=("--fix-openssl")
    opts+=("connect")
    opts+=("--as-gateway")

    opts+=("${server}")

    if $debug; then
        opts+=("-vv")
    fi

    mdebug "call: $call"
    mdebug "user: $user"
    if [[ -n $pwd ]]; then
        mdebug "pwd: <hidden>"
    else
        mdebug "pwd: <not specified>"
    fi
    mdebug "opts: [n=${#opts[@]}] ${opts[*]}"
    mdebug "call: sudo UCSF_VPN_VERSION=$(version) UCSF_VPN_LOGFILE=$(logfile) gpclient ${opts[*]}"

    mnote "Open the Duo Mobile app on your smartphone or tablet to confirm ..."

    minfo "Connecting to VPN server '${server}'"

    if $dryrun; then
        _exit 0
    fi

    log_file="$(logfile)"
    gpclient_log_file="$(gpclient_logfile)"
    rm "${log_file}"
    log "gpclient_start() ..."
    
    ## Record IP routing table before connecting to the VPN
    ip route show > "${ip_route_novpn_file}"

    ## Record hostname resolve file before connecting to the VPN
    cat /etc/resolv.conf > "${resolv_novpn_file}"
    
    log "ip route show:"
    ip route show >> "${log_file}"

    # shellcheck disable=SC2086
    sudo UCSF_VPN_VERSION="$(version)" UCSF_VPN_LOGFILE="$(logfile)" gpclient "${opts[@]}" 2> "${gpclient_log_file}" 1> "${gpclient_log_file}" &
    gpclient_pid=$!
    echo "${gpclient_pid}" > "${pid_file}"
    mdebug "gpclient PID: ${gpclient_pid}"
    
    ## Enter credential in 'GlobalProtect Login' pop-up window
    while ! xdotool search --name "GlobalProtect Login" > /dev/null 2>&1; do
        sleep 0.5
    done
    
    sleep 0.5
    WINDOW_ID=$(xdotool search --name "GlobalProtect Login" | head -1)
    mdebug "WINDOW_ID=${WINDOW_ID} (the 'GlobalProtect Login' window)"
    if [[ -z ${WINDOW_ID} ]]; then
        merror "Failed to locate the 'GlobalProtect Login' pop-up window"
    fi
    
    xdotool windowfocus "${WINDOW_ID}"
    sleep 0.5
    
    echo "* Entering UCSF VPN credentials"
    xdotool mousemove --window "${WINDOW_ID}" 50 50 click 1
    sleep 0.5
    
    xdotool key --window "${WINDOW_ID}" Tab
    xdotool key --window "${WINDOW_ID}" ctrl+a
    xdotool type --window "${WINDOW_ID}" "${user}"
    echo "Login name: ${user}"
    xdotool key --window "${WINDOW_ID}" Tab
    xdotool key --window "${WINDOW_ID}" ctrl+a
    xdotool type --window "${WINDOW_ID}" "${pwd}"
    echo "Password: ${pwd//?/*}"
    xdotool key --window "${WINDOW_ID}" Tab
    xdotool key --window "${WINDOW_ID}" Return
    
    ## Update IP-info file
    pii_file=$(make_pii_file)

    pid=$(gpclient_pid)
    mdebug "pid=$pid"
    if [[ $pid == -1 ]]; then
        cat "${gpclient_log_file}"

        ## Report on ping for VPN server
        if ! is_online "${server}"; then
            main_reason="Most likely reason: The VPN server (${server}) does not respond to ping; check your internet connection."
        else
            post_reason="Miscellaneous: The VPN server (${server}) responds to ping"
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
        if grep -q -F "username:password" "${gpclient_log_file}"; then
            reason="Incorrect username or password"
            reason="${reason}. You can test your credentials via the Web VPN at https://${UCSF_WEB_VPN_SERVER:-remote-vpn01.ucsf.edu}/"
        elif grep -q -F "Inappropriate ioctl for device" "${gpclient_log_file}"; then
            reason="Incorrect username or password"
            reason="${reason}. You can test your credentials via the Web VPN at https://${UCSF_WEB_VPN_SERVER:-remote-vpn01.ucsf.edu}/"
        elif grep -q -E "password#2" "${gpclient_log_file}"; then
            reason="2FA token not accepted"
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

    ## Record hostname resolve file after having connected to the VPN
    cat /etc/resolv.conf > "${resolv_vpn_file}"

    default_route_after=$(grep -E '^default[[:space:]].*tun' "${ip_route_vpn_file}" | sed 's/default //' | sed -E 's/ +$//')
    mdebug "Default IP routing changed to: ${default_route_after}"
    
    if $debug; then
        mdebug "Changes made to the IP routing table (ip route show):"
        {
            _tput setaf 8 ## gray
            diff -u -w "${ip_route_novpn_file}" "${ip_route_vpn_file}"
            _tput sgr0    ## reset
        } 1>&2

        mdebug "Changes made to /etc/resolv.conf:"
        {
            _tput setaf 8 ## gray
            diff -u -w "${resolv_novpn_file}" "${resolv_vpn_file}"
            _tput sgr0    ## reset
        } 1>&2
    fi

    if $verbose; then
      default_route_before=$(grep -E '^default[[:space:]]' "${ip_route_novpn_file}" | sed 's/default //' | sed -E 's/ +$//')
      minfo "Default IP routing was changed from '${default_route_before}' to '${default_route_after}'"
    fi

    log "gpclient_start() ... done"
    
    minfo "Connected to VPN server"
}

function gpclient_stop() {
    local kill_timeout
    local -i kk pid

    mdebug "gpclient_stop() ..."

    log "gpclient_stop() ..."
    
    pid=$(gpclient_pid)
    if [[ $pid == -1 ]]; then
        mwarn "Could not detect a VPN ('gpclient') process. Skipping."
        return
#        merror "Failed to located a VPN ('gpclient') process. Are you really connected by VPN? If so, you could manually kill *all* gpclient processes by calling 'sudo pkill -INT gpclient'. CAREFUL!"
    fi

    minfo "Disconnecting from VPN server"

    assert_sudo "stop"

    ## Record IP routing table while still connected to the VPN
    ip route show > "${ip_route_vpn_file}"

    ## Record hostname resolve file while still connected to the VPN
    cat /etc/resolv.conf > "${resolv_vpn_file}"
    
    ## Signal SIGINT to terminate gpclient. If the first one fails,
    ## try another one
    # shellcheck disable=SC2034
    for kk in {1..2}; do
        ## From 'man gpclient': SIGINT performs a clean shutdown by logging the
        ## session off, disconnecting from the gateway, and running the vpnc-script
        ## to restore the network configuration.
        mdebug "Killing gpclient process: sudo kill -s INT \"$pid\" 2> /dev/null"
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
        merror "Failed to terminate VPN process ('gpclient' with PID $pid). You could manually kill *all* gpclient processes by calling 'sudo pkill -INT gpclient'. CAREFUL!"
    fi

    ## gpclient should remove PID file when terminated properly,
    ## but if not, let us remove it here
    if [[ -f "$pid_file" ]]; then
        rm -f "$pid_file"
        mwarn "gpclient PID file removed manually: $pid_file"
    fi

    ## Wait for IP routing table to stabilize
    wait_for_ip_route
    
    ## Record IP routing table after being disconnected from the VPN
    ip route show > "${ip_route_novpn_file}"

    ## Record hostname resolve file after being disconnected from the VPN
    cat /etc/resolv.conf > "${resolv_novpn_file}"
    
    default_route_after=$(grep -E '^default[[:space:]]' "${ip_route_novpn_file}" | sed 's/default //' | sed -E 's/ +$//')
    mdebug "Default IP routing changed to: ${default_route_after}"

    
    if $debug; then
        mdebug "Changes made to the IP routing table (ip route show):"
        {
            _tput setaf 8 ## gray
            diff -u -w "${ip_route_vpn_file}" "${ip_route_novpn_file}"
            _tput sgr0    ## reset
        } 1>&2

        mdebug "Changes made to /etc/resolv.conf:"
        {
            _tput setaf 8 ## gray
            diff -u -w "${resolv_vpn_file}" "${resolv_novpn_file}"
            _tput sgr0    ## reset
        } 1>&2
    fi
    
    if $verbose; then
      default_route_before=$(grep -E '^default[[:space:]].*tun' "${ip_route_vpn_file}" | sed 's/default //' | sed -E 's/ +$//')
      minfo "Default IP routing was changed from '${default_route_before}' to '${default_route_after}'"
    fi

    log "gpclient_stop() ... done"

    minfo "Disconnected from VPN server"
}


function gpclient_reconnect() {
    local kill_timeout
    local -i kk pid

    mdebug "gpclient_reconnect() ..."

    log "gpclient_reconnect() ..."
    
    pid=$(gpclient_pid)
    if [[ $pid == -1 ]]; then
        mwarn "Could not detect a VPN ('gpclient') process. Skipping."
        return
    fi

    minfo "Reconnecting to VPN server"

    assert_sudo "stop"

    ## From 'man gpclient': SIGUSR2 forces an immediate disconnection and
    ## reconnection; this can be used to quickly recover from LAN IP address
    ## changes.
    mdebug "sudo kill -s USR2 $pid"
    log "- sudo kill -s USR2 $pid"
    sudo kill -s USR2 $pid 2> /dev/null

    status "connected"

    log "gpclient_reconnect() ... done"

    minfo "Reconnected to VPN server"
}
