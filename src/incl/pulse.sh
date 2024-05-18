# -------------------------------------------------------------------------
# Pulse Secure Client
# -------------------------------------------------------------------------
function div() {
    if [ "$2" == "1" ] || [ "$2" == "1.0" ]; then
        echo "$1"
    else
        # shellcheck disable=SC2003
        echo "$1/$2" | bc -l
    fi
}

function pulsesvc_version() {
    local res

    res=$(pulsesvc --version 2> /dev/null)
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        echo "<PLEASE INSTALL>"
    else
        printf "%s\\n" "${res[@]}" | grep -F "Release Version" | sed -E 's/.*:[ ]+//'
    fi
}

function is_pulseUi_running() {
    ps -C pulseUi > /dev/null
}

function pulseUi_find_connection() {
    local config_home confile con  # IFS too?
    local -i idx ii

    config_home="$HOME/.pulse_secure/pulse"
    confile="$config_home/.pulse_Connections.txt"
    [[ -f "$confile" ]] || pulseUi_add_connection
    [[ -f "$confile" ]] || merror "No Pulse GUI connection file: $confile"
    mdebug "Pulse connections file: $confile"
    mdebug "$(< "$confile")"

    # shellcheck disable=SC2207
    IFS=$'\r\n' cons=( $(grep -E "^[ \\t]*{.+}[ \\t]*$" < "$confile") )
    mdebug "Number of connections: ${#cons[@]}"
    mdebug "Searching for VPN URL: $url"

    idx=-1
    for ii in "${!cons[@]}"; do
        con="${cons[$ii]/^ */}"
        mdebug "- connection $ii: $con"
        if echo "$con" | grep -q -F "\"$url\"" &> /dev/null; then
            idx=$ii
            break
        fi
    done

    mdebug "Index of connection found: $idx"

    echo $idx
}

function pulseUi_add_connection() {
    local config_home confile name con

    config_home="$HOME/.pulse_secure/pulse"
    confile="$config_home/.pulse_Connections.txt"
    name="UCSF"
    mdebug "Pulse connections file: $confile"
    con="{\"connName\": \"$name\", \"preferredCert\": \"\", \"baseUrl\": \"$url\"}"
    mdebug "Appending connection: $con"
    echo "$con" >> "$confile"
    mecho "Appended missing '$name' connection: $url"
}

function pulse_start_gui() {
    if is_pulseUi_running; then
        mwarn "Pulse Secure GUI is already running"
        return
    fi

    ## Start the Pulse Secure GUI
    ## NOTE: Sending stderr to dev null to silence warnings on
    ## "(pulseUi:26614): libsoup-CRITICAL **: soup_cookie_jar_get_cookies:
    ##  assertion 'SOUP_IS_COOKIE_JAR (jar)' failed"
    mdebug "Pulse Secure GUI client: $(command -v pulseUi)"
    minfo "Launching the Pulse Secure GUI ($(command -v pulseUi))"
    pulseUi 2> /dev/null &
}

function pulse_open_gui() {
    if ! $force; then
      if is_connected; then
          mwarn "Already connected to the VPN [$(public_info)]"
          _exit 0
      fi
    fi

    mdebug "call: $call"
    mdebug "call: pulseUi"

    if $dryrun; then
        _exit 0
    fi

    ## Start the Pulse Secure GUI
    pulse_start_gui
}

function pulse_close_gui() {
    if ! is_pulseUi_running; then return; fi

    mdebug "Closing Pulse Secure GUI"

    ## Try with 'xdotool'?
    if command -v xdotool &> /dev/null; then
        xdotool search --all --onlyvisible --pid "$(pidof pulseUi)" --name "Pulse Secure" windowkill
    else
        pkill -QUIT pulseUi && mdebug "Killed Pulse Secure GUI"
    fi
}

function wait_for_pulse_window_to_close() {
    local wid wids

    wid=$1
    mdebug "Waiting for Pulse Secure Window ID ($wid) to close ..."
    while true; do
       wids=$(xdotool search --all --onlyvisible --name "Pulse Secure")
       echo "$wids" | grep -q "$wid" && break
       sleep 0.2
    done
    mdebug "Waiting for Pulse Secure Window ID ($wid) to close ... done"
}

function pulse_start() {
    local wid wid2 wid3 cmd opts extra
    local -i conidx step

    ## Validate request
    if [[ "$realm" == "Dual-Factor Pulse Clients" ]]; then
        if ! $gui; then
            merror "Using --realm='$realm' (two-factor authentication; 2FA) is not supported when using --no-gui"
        fi
    elif [[ "$realm" == "Single-Factor Pulse Clients" ]]; then
        if [ -n "${token}" ] && [ "${token}" != "false" ]; then
            merror "Passing a --token='$token' with --realm='$realm' (two-factor authentication; 2FA) does not make sense"
        fi
    fi
    if [ -n "${token}" ] && [ "${token}" != "false" ]; then
        if ! $gui; then
            merror "Using --token='$token' suggests two-factor authentication (2FA), which is currently not supported when using --no-gui"
        fi
    fi

    if ! $force; then
      if is_connected; then
          mwarn "Already connected to the VPN [$(public_info)]"
          _exit 0
      fi
    fi

    ## Check for valid connection in Pulse Secure GUI
    conidx=-1
    if $gui; then
        ## If Pulse Secure GUI is open, we need to close it
        ## before peeking at its connections config file.
        if is_pulseUi_running; then
            close_gui
            sleep "$(div 0.5 "$speed")"
        fi
        conidx=$(pulseUi_find_connection)
        [[ $conidx -eq -1 ]] && pulseUi_add_connection
        conidx=$(pulseUi_find_connection)
        [[ $conidx -eq -1 ]] && merror "Pulse Secure GUI does not have a connection for the VPN: $url"
    fi

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

    if $gui; then
        step=1

        ## Check for 'xdotool'
        command -v xdotool &> /dev/null || merror "Cannot enter credentials in GUI, because 'xdotool' could not be located."

        ## Start Pulse Secure GUI
        pulse_start_gui

        sleep "$(div 1.0 "$speed")"
        wid=$(xdotool search --all --onlyvisible --pid "$(pidof pulseUi)" --name "Pulse Secure")
        if [[ -z "$wid" ]]; then
            merror "Failed to locate the Pulse Secure GUI window"
        fi
        mecho "Pulse Secure GUI automation:"
        mdebug "Pulse Secure Window ID: $wid"
        mdebug "Clicking pulseUi 'Connect': $((7 + 2 * conidx)) TABs + ENTER"
        cmd="xdotool search --all --onlyvisible --pid $(pidof pulseUi) --name 'Pulse Secure' windowmap --sync windowactivate --sync windowfocus --sync windowraise mousemove --window %1 --sync 0 0 sleep 0.1 click 1 sleep 0.1 key --delay 50 --repeat "$((7 + 2 * conidx))" Tab sleep 0.1 key Return"
        mdebug " - $cmd"
        mecho " ${step}. selecting connection"
        step=$((step + 1))
        eval "$cmd"

        mdebug "Minimizing Pulse Secure GUI"
        xdotool windowminimize "$wid"

        sleep "$(div 2.0 "$speed")"
        wid2=$(xdotool search --all --onlyvisible --name "Pulse Secure")
        mdebug "Pulse Secure Window IDs: $wid2"
        wid2=$(echo "$wid2" | grep -vF "$wid")
        mdebug "Pulse Secure Popup Window ID: $wid2"
        if [[ -z "$wid2" ]]; then
            merror "Failed to locate the Pulse Secure GUI popup window"
        fi

        ## Click-through UCSF announcement message?
        if $notification; then
            mdebug "Clicking on 'Proceed'"
            cmd="xdotool windowactivate --sync $wid2 key --delay 50 --repeat 2 Tab key Return"
            mdebug " - $cmd"
            eval "$cmd"
            mecho " ${step}. clicking through UCSF notification popup window (--no-notification if it doesn't exist)"
            step=$((step + 1))
            sleep "$(div 2.0 "$speed")"
        else
            mecho " ${step}. skipping UCSF notification popup window (--notification if it exists)"
            step=$((step + 1))
        fi

        mdebug "Entering user credentials (username and password)"
        xdotool windowactivate --sync "$wid2" type "$user"
        xdotool windowactivate --sync "$wid2" key --delay 50 Tab type "$pwd"
        ## Single- or Dual-Factor Pulse Clients?
        extra=
        [[ "$realm" == "Dual-Factor Pulse Clients" ]] && extra="Down"
        cmd="xdotool windowactivate --sync $wid2 key --delay 50 Tab $extra Tab Return"
        mdebug " - $cmd"
        eval "$cmd"
        mecho " ${step}. entering user credentials and selecting realm"
        step=$((step + 1))


        if [[ ${token} != "false" ]]; then
            mdebug "Using two-factor authentication (2FA) token"

            sleep "$(div 1.0 "$speed")"
            wid3=$(xdotool search --all --onlyvisible --name "Pulse Secure")
            mdebug "Pulse Secure Window IDs: $wid3"
            wid3=$(echo "$wid3" | grep -vF "$wid")
            mdebug "Pulse Secure Popup Window ID: $wid3"
            if [[ -z "$wid3" ]]; then
                merror "Failed to locate the Pulse Secure GUI popup window"
            fi

            mdebug "Entering token"
            mecho " ${step}. entering 2FA token"
            step=$((step + 1))
            cmd="xdotool windowactivate --sync $wid3 type $token"
            mdebug " - $cmd"
            eval "$cmd"
            cmd="xdotool windowactivate --sync $wid3 key Return"
            mdebug " - $cmd"
            eval "$cmd"

            ## Wait for popup window to close
            wait_for_pulse_window_to_close "$wid3"
        else
            ## Wait for popup window to close
            wait_for_pulse_window_to_close "$wid2"
        fi
        mecho " ${step}. connecting ..."
        step=$((step + 1))
    else
      if [[ "$realm" == "Dual-Factor Pulse Clients" ]]; then
          merror "Using --realm='$realm' (two-factor authentication; 2FA) is not supported when using --no-gui"
      fi
      if [ -n "${token}" ] && [ "${token}" != "false" ]; then
          merror "Using --token='$token' suggests two-factor authentication (2FA), which is currently not supported when using --no-gui"
      fi
      ## Pulse Secure options
      opts="${extras[*]}"
      opts="$opts -h ${server}"

      if [[ -n $user ]]; then
          opts="-u $user $opts"
      fi

      if ! $debug; then
          opts="-log-level 5 $opts"
      fi

      mdebug "call: $call"
      mdebug "user: $user"
      if [[ -n $pwd ]]; then
          mdebug "pwd: <hidden>"
      else
          mdebug "pwd: <not specified>"
      fi
      mdebug "opts: $opts"
      mdebug "call: pulsesvc $opts -r \"${realm}\""

      if $dryrun; then
          if [[ -n $pwd ]]; then
              echo "echo \"<pwd>\" | pulsesvc $opts -r \"${realm}\" | grep -viF password &"
          else
              echo "pulsesvc $opts -r \"${realm}\" &"
          fi
          _exit 0
      fi

      if [[ -n $pwd ]]; then
          echo "$pwd" | pulsesvc "$opts" -r "${realm}" | grep -viF password &
      else
          pulsesvc "$opts" -r "${realm}" &
      fi
    fi
}

function pulse_stop() {
    if ! $force; then
      if is_connected; then
          ## Close/kill the Pulse Secure GUI
          pulse_close_gui

          mwarn "Already connected to the VPN [$(public_info)]"
          _exit 0
      fi
      mdebug "Public IP (before): $ip"
    fi

    ## Close/kill the Pulse Secure GUI
    pulse_close_gui

    ## Kill any running pulsesvc processes
    pulsesvc -Kill
    mdebug "Killed local ('pulsesvc') VPN process"
}


function pulse_troubleshoot() {
    local config_home confile match con prefix logfile ## IFS too?
    local -i ii

    minfo "Assumed path to Pulse Secure (PULSEPATH): $PULSEPATH"
    command -v pulsesvc || merror "Pulse Secure software 'pulsesvc' not found (in neither PULSEPATH nor PATH)."

    minfo "Pulse Secure software: $res"
    pulsesvc --version

    config_home="$HOME/.pulse_secure/pulse"
    [[ -d "$config_home" ]] || merror "Pulse user-specific folder: $config_home"
    minfo "Pulse user configuration folder: $config_home"

    confile="$config_home/.pulse_Connections.txt"
    [[ -f "$confile" ]] || merror "No Pulse GUI connection file: $confile"
    minfo "Pulse connections file: $confile"
    # shellcheck disable=SC2207
    IFS=$'\r\n' cons=( $(grep -E "^[ \\t]*{.+}[ \\t]*$" < "$confile") )
    minfo "Number of connections: ${#cons[@]}"
    match=false
    for ii in "${!cons[@]}"; do
        con="${cons[$ii]/^ */}"
        if echo "$con" | grep -q -F "\"$url\"" &> /dev/null; then
            prefix=">>>"
            match=true
        else
            prefix="   "
        fi
        >&2 printf " %s %d. %s\\n" "$prefix" "$((ii + 1))" "${con/ *$/}"
    done
    if $match; then
        minfo "Found connection with URL of interest: $url"
    else
        mwarn "No connection with URL of interest: $url"
    fi

    logfile="$config_home/pulsesvc.log"
    [[ -f "$logfile" ]] || merror "No log file: $logfile"

    minfo "Log file: $logfile"
    grep -q -F Error "$logfile" &> /dev/null || { mok "No errors found: $logfile"; _exit 0; }

    mwarn "Detected the following errors in the log file: $(grep -F Error "$logfile" | >&2 tail -3)"
}
