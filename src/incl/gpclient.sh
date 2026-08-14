# -------------------------------------------------------------------------
# gplient: The GlobalProtect VPN client
# -------------------------------------------------------------------------
function curl_version() {
    local out

    out=$(curl --version 2> /dev/null)
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        echo "<PLEASE INSTALL>"
    else
        printf "%s\\n" "${out}" | grep -E "^curl" | sed -E 's/^curl +//' | sed -E 's/ .*//'
    fi
}

function gpclient_version() {
    local out

    out=$(gpclient --version 2> /dev/null)
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        echo "<PLEASE INSTALL>"
    else
        printf "%s\\n" "${out}" | sed -E 's/^gpclient +//' | sed -E 's/ .*//'
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
## Usage: gpclient_abort <pid>
## Terminates a 'gpclient' process that we started, but never got connected,
## e.g. because the user interrupted the login step. If we leave it running,
## the next 'ucsf-vpn start' will mistake it for an established VPN connection
# shellcheck disable=SC2329  ## It is invoked indirectly, i.e. by 'trap'
function gpclient_abort() {
    local -i pid

    ## Disable the traps that take us here, because we call _exit() below,
    ## which would otherwise take us here again
    trap - INT TERM HUP EXIT

    pid=${1:-0}
    mdebug "gpclient_abort(pid=${pid}) ..."
    log "gpclient_abort(pid=${pid}) ..."

    mwarn "The VPN connection was not established"

    if [[ ${pid} -gt 0 ]] && ps -p "${pid}" > /dev/null; then
        minfo "Terminating the VPN process that was started ('gpclient' PID ${pid})"
        ## Note, we must not prompt for a password from within a signal
        ## handler, which is why we use 'sudo -n' here
        sudo -n kill -s TERM "${pid}" 2> /dev/null
        timeout 5 tail --pid="${pid}" -f /dev/null
        if ps -p "${pid}" > /dev/null; then
            mwarn "Failed to terminate the VPN process ('gpclient' PID ${pid}). Terminate it manually with 'sudo kill ${pid}', otherwise the next 'ucsf-vpn start' will report that you are already connected"
        else
            ## Any 'gpauth' login window is orphaned when 'gpclient' terminates
            pkill -TERM -u "$USER" -x gpauth 2> /dev/null
        fi
    fi

    if [[ -f "$pid_file" ]]; then
        mdebug "Removing PID file: $pid_file"
        rm -f "$pid_file"
    fi

    _exit 1
}


function gpclient_start() {
    local gpclient_pid gpclient_log_file log_file main_reason reason post_reason
    local opt use_xdotool
    local -a connect_opts global_opts opts
    local -i auth_timeout max_iter pid

    mdebug "gpclient_start() ..."

    pid=$(gpclient_pid)
    if [[ $pid != -1 ]]; then
        ## A 'gpclient' process without a VPN tunnel is not a VPN connection.
        ## It is a login that never completed, e.g. because a previous
        ## 'ucsf-vpn start' was interrupted. Note that not even --force will
        ## start a second VPN process; the running one has to be terminated
        ## first, which is what 'ucsf-vpn stop' and 'ucsf-vpn restart' do
        if ! has_ip_route_tunnel; then
            merror "A VPN process ('gpclient' PID $pid) is running, but there is no VPN tunnel, i.e. you are not connected to the VPN. Was a previous 'ucsf-vpn start' interrupted before the login completed? If so, call 'ucsf-vpn stop' to terminate that process, or 'ucsf-vpn restart' to reconnect from scratch"
        fi
        if ! $force && [[ $validate == *pid* ]]; then
            mwarn "Skipping - already connected to the VPN"
            return
        fi
        merror "A VPN process ('gpclient' PID $pid) is already running. Call 'ucsf-vpn stop' to disconnect from the VPN, or 'ucsf-vpn restart' to reconnect"
    fi

    if ! $force; then
        if [[ $validate == *ipinfo* ]] && is_connected; then
           mwarn "Skipping - already connected to the VPN"
           return
        fi
    fi

    ## Assert that there is no PID file left from a VPN process that is no
    ## longer running. Note, gpclient_pid() removes such stray PID files
    if [[ -f "$pid_file" ]]; then
        merror "Detected a PID file, but no VPN process running: '$pid_file'. Remove it with 'rm $pid_file', and try again"
    fi

    if ! is_online; then
        merror "Internet connection is not working"
    fi

    minfo "Preparing to connect to VPN server '${server}'"

    assert_sudo "start"

    ## Is the login pop-up window automated by 'xdotool'? Only on X11, because
    ## 'xdotool' can only see X11 windows, i.e. on Wayland it would wait forever
    ## for a window that it can never find. There is also no pop-up window to
    ## automate, when we sign in via an external web browser
    use_xdotool=true
    if [[ -n "${browser}" ]]; then
        mdebug "Signing in via an external web browser ('${browser}'), i.e. there is no login pop-up window to automate"
        use_xdotool=false
    elif [[ "${XDG_SESSION_TYPE}" != "x11" ]]; then
        mdebug "Not an X11 session (XDG_SESSION_TYPE='${XDG_SESSION_TYPE}'), i.e. cannot automate the login pop-up window"
        use_xdotool=false
    fi

    ## The user credentials are only used for automating the login pop-up
    ## window, i.e. don't ask for them, if we don't need them
    if $use_xdotool; then
        ## Load user credentials from file?
        source_netrc

        ## Prompt for username and password, if missing
        prompt_user "${user}"
        prompt_pwd "${pwd}"
    fi

    ## Options passed via --args, and UCSF_VPN_EXTRAS, are either 'gpclient'
    ## options, which have to be passed before the 'connect' command, or
    ## 'gpclient connect' options, which have to be passed after it
    global_opts=()
    connect_opts=()
    for opt in "${extras[@]}"; do
        case "${opt}" in
            --fix-openssl)
                ## We always pass this one, and 'gpclient' rejects duplicates
                mdebug "Dropping '${opt}', because it is always passed"
                ;;
            --ignore-tls-errors|-v|-vv|-vvv|--verbose|-q|-qq|--quiet)
                global_opts+=("${opt}")
                ;;
            *)
                connect_opts+=("${opt}")
                ;;
        esac
    done
    ## Sign in via an external web browser? Note that 'gpclient' rejects a
    ## duplicated --browser option, which is why we assert there is only one
    if [[ -n "${browser}" ]]; then
        for opt in "${connect_opts[@]}"; do
            if [[ "${opt}" == "--browser" ]] || [[ "${opt}" == --browser=* ]]; then
                merror "Cannot use both --browser and '${opt}', where the latter was passed via --args or UCSF_VPN_EXTRAS"
            fi
        done
        connect_opts+=("--browser=${browser}")
    fi

    mdebug "gpclient options: [n=${#global_opts[@]}] ${global_opts[*]}"
    mdebug "gpclient connect options: [n=${#connect_opts[@]}] ${connect_opts[*]}"

    ## gpclient options
    opts=()
    opts+=("${global_opts[@]}")

    opts+=("--fix-openssl")
    opts+=("connect")
    opts+=("${connect_opts[@]}")
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

    mnote "Open the Duo Mobile app on your smartphone to confirm, unless recently authenticated ..."

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

    # shellcheck disable=SC2024
    sudo UCSF_VPN_VERSION="$(version)" UCSF_VPN_LOGFILE="$(logfile)" gpclient "${opts[@]}" > "${gpclient_log_file}" 2>&1 &
    
    gpclient_pid=$!
    echo "${gpclient_pid}" > "${pid_file}"
    mdebug "gpclient PID: ${gpclient_pid}"

    ## From here on, and until the VPN tunnel is up, 'ucsf-vpn' must not leave
    ## the 'gpclient' process behind, neither when interrupted, nor when giving
    ## up itself, e.g. when the login takes too long. The latter is why we trap
    ## also EXIT, which covers all calls to merror() further down
    # shellcheck disable=SC2064
    trap "gpclient_abort ${gpclient_pid}" INT TERM HUP EXIT
    
    if $use_xdotool; then
        ## Enter credential in 'GlobalProtect Login' pop-up window
        mdebug "Wait for 'GlobalProtect Login' pop-up window to appear"
        max_iter=60 ## Wait for up to 30 seconds
        while ! xdotool search --name "GlobalProtect Login" > /dev/null 2>&1; do
            max_iter=$((max_iter - 1))
            if [[ ${max_iter} -le 0 ]]; then
                merror "The 'GlobalProtect Login' pop-up window never appeared. If the VPN server authenticates via single sign-on, then the pop-up window is a web page, which cannot be automated"
            fi
            sleep 0.5
        done

        sleep 0.5
        WINDOW_ID=$(xdotool search --name "GlobalProtect Login" | head -1)
        mdebug "'GlobalProtect Login' window WINDOW_ID=${WINDOW_ID}"
        if [[ -z ${WINDOW_ID} ]]; then
            merror "Failed to locate the 'GlobalProtect Login' pop-up window"
        fi

        mdebug "'GlobalProtect Login' window: focus window"
        xdotool windowfocus "${WINDOW_ID}"
        sleep 0.5

        mdebug "'GlobalProtect Login' window: unfocus form"
        xdotool mousemove --window "${WINDOW_ID}" 50 50 click 1
        sleep 0.5

        mdebug "'GlobalProtect Login' window: move to 'Login name' field"
        xdotool key --window "${WINDOW_ID}" Tab
        xdotool key --window "${WINDOW_ID}" ctrl+a
        mdebug "'GlobalProtect Login' window: type 'Login name' (${user})"
        xdotool type --window "${WINDOW_ID}" "${user}"

        mdebug "'GlobalProtect Login' window: move to 'Password' field"
        xdotool key --window "${WINDOW_ID}" Tab
        xdotool key --window "${WINDOW_ID}" ctrl+a
        mdebug "'GlobalProtect Login' window: type 'Password' (${pwd//?/*})"
        xdotool type --window "${WINDOW_ID}" "${pwd}"

        mdebug "'GlobalProtect Login' window: Press ENTER"
        xdotool key --window "${WINDOW_ID}" Tab
        xdotool key --window "${WINDOW_ID}" Return

        mdebug "Wait for 'GlobalProtect Login' pop-up window to close"
        while xdotool search --name "GlobalProtect Login" > /dev/null 2>&1; do
            sleep 0.5
        done

        mdebug "'GlobalProtect Login' closed"
    elif [[ -n "${browser}" ]]; then
        mnote "Sign in to the VPN in the web browser that just opened, and confirm with Duo, if asked to. Finally, when the web browser asks to open 'GP Connect', confirm that too, because that is how the sign-in is passed back to the VPN client ..."
    else
        mnote "Enter your credentials in the 'GlobalProtect' pop-up window that just opened, and confirm with Duo, if asked to ..."
    fi

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

    ## Wait for VPN tunnel to appear in IP routing table. This is also where we
    ## wait for the user to sign in, including two-factor authentication, which
    ## is why the timeout is generous
    auth_timeout=${UCSF_VPN_AUTH_TIMEOUT:-300}
    wait_for_ip_route_tunnel "${auth_timeout}" "${gpclient_pid}"

    ## The VPN tunnel is up. From here on, an interrupted 'ucsf-vpn' should
    ## leave the VPN connection running, which 'ucsf-vpn stop' terminates
    trap - INT TERM HUP EXIT
    
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
#        merror "Failed to located a VPN ('gpclient') process. Are you really connected by VPN? If so, you could manually kill *all* gpclient processes by calling 'sudo pkill -TERM gpclient'. CAREFUL!"
    fi

    minfo "Disconnecting from VPN server"

    assert_sudo "stop"

    ## Record IP routing table while still connected to the VPN
    ip route show > "${ip_route_vpn_file}"

    ## Record hostname resolve file while still connected to the VPN
    cat /etc/resolv.conf > "${resolv_vpn_file}"
    
    ## Signal SIGTERM to terminate gpclient. If the first one fails,
    ## try another one
    # shellcheck disable=SC2034
    for kk in {1..2}; do
        mdebug "Terminating gpclient process: sudo kill -s TERM \"$pid\" 2> /dev/null"
        log "- sudo kill -s TERM $pid"
        sudo kill -s TERM $pid 2> /dev/null
    
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
        merror "Failed to terminate VPN process ('gpclient' with PID $pid). You could manually kill *all* gpclient processes by calling 'sudo pkill -TERM gpclient'. CAREFUL!"
    fi

    if [[ -f "$pid_file" ]]; then
        rm -f "$pid_file"
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
