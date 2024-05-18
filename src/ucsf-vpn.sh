#! /usr/bin/env bash
### Connect to and Disconnect from the UCSF VPN
###
### Usage:
###  ucsf-vpn <command> [flags] [options]
###
### Commands:
###  start            Connect to VPN
###  stop             Disconnect from VPN
###  restart          Disconnect and reconnect to VPN
###  toggle           Connect to or disconnect from VPN
###  status           Display VPN connection status
###  details          Display connection details in JSON format
###  routing          Display IP routing details
###  log              Display log file
###  troubleshoot     Scan log file for errors (only for '--method=pulse')
###
### Options:
###  --token=<token>  One-time two-factor authentication (2FA) token or method:
###                    - 'prompt' (user is prompted to enter the token),
###                    - 'push' ("approve and confirm" in Duo app; default),
###                    - 'phone' (receive phone call and "press any key"),
###                    - 'sms' (receive code via text message),
###                    -  6 or 7 digit token (from Duo app), or
###                    -  44-letter YubiKey token ("press YubiKey")
###  --user=<user>    UCSF Active Directory ID (username)
###  --pwd=<pwd>      UCSF Active Directory ID password
###  --presudo=<lgl>  Established sudo upfront (true; default) or not (false)
###
###  --server=<host>  VPN server (default is 'remote.ucsf.edu')
###  --realm=<realm>  VPN realm (default is 'Dual-Factor Pulse Clients')
###  --url=<url>      VPN URL (default is https://{{server}}/pulse)
###  --method=<mth>   Either 'openconnect' (default) or 'pulse' (deprecated)
###  --protocol=<ptl> VPN protocol, e.g. 'nc' (default) and 'pulse'
###  --validate=<how> One or more of 'ipinfo', 'iproute', and 'pid', e.g.
###                   'pid,iproute,ipinfo' (default)
###  --theme=<theme>  Either 'cli' (default) or 'none'
###  --flavor=<flvr>  Use a customized flavor of the VPN
###
### Flags:
###  --verbose        More verbose output
###  --help           Display full help
###  --version        Display version
###  --full           Display more information
###  --force          Force command
###  --args           Pass any remaining options to 'openconnect'
###
### Examples:
###  ucsf-vpn --version --full
###  ucsf-vpn start --user=alice --token=push
###  ucsf-vpn stop
###  UCSF_VPN_TOKEN=prompt ucsf-vpn start --user=alice --pwd=secrets
###  ucsf-vpn start
###  ucsf-vpn routings --full
###
### ---
###
### Environment variables:
###  UCSF_VPN_METHOD       Default value for --method
###  UCSF_VPN_PROTOCOL     Default value for --protocol
###  UCSF_VPN_SERVER       Default value for --server
###  UCSF_VPN_TOKEN        Default value for --token
###  UCSF_VPN_THEME        Default value for --theme
###  UCSF_VPN_VALIDATE     Default value for --validate
###  UCSF_VPN_PING_SERVER  Ping server to validate internet (default: 9.9.9.9)
###  UCSF_VPN_PING_TIMEOUT Ping timeout (default: 1.0 seconds)
###  UCSF_VPN_EXTRAS       Additional arguments passed to OpenConnect
###
### Commands and Options for Pulse Security Client only (--method=pulse):
###  open-gui         Open the Pulse Secure GUI
###  close-gui        Close the Pulse Secure GUI (and any VPN connections)
###
###  --gui            Connect to VPN via Pulse Secure GUI
###  --no-gui         Connect to VPN via Pulse Secure CLI (default)
###  --speed=<factor> Control speed of --gui interactions (default is 1.0)
###
### Any other options are passed to Pulse Secure CLI as is (only --no-gui).
###
### User credentials:
### If user credentials (--user and --pwd) are neither specified nor given
### in ~/.netrc, then you will be prompted to enter them. To specify them
### in ~/.netrc file, use the following format:
###
###   machine remote.ucsf.edu
###       login alice
###       password secrets
###
### For security, the ~/.netrc file should be readable only by
### the user / owner of the file. If not, then 'ucsf-vpn start' will
### set its permission accordingly (by calling chmod go-rwx ~/.netrc).
###
### Requirements:
### * Requirements when using OpenConnect (CLI):
###   - OpenConnect (>= 7.08) (installed: {{openconnect_version}})
###   - sudo
### * Requirements when using Junos Pulse Secure Client (GUI):
###   - Junos Pulse Secure client (>= 5.3) (installed: {{pulsesvc_version}})
###   - Ports 4242 (UDP) and 443 (TCP)
###   - `curl`
###   - `xdotool` (when using 'ucsf-vpn start --method=pulse --gui')
###   - No need for sudo rights
###
### VPN Protocol:
### Different versions of OpenConnect support different VPN protocols.
### Using '--protocol=nc' (default) has been confirmed to work when using
### OpenConnect 7.08, and '--protocol=pulse' for OpenConnect 8.10.
### The 'nc' protocol specifies the old "Juniper Network Connect" protocol,
### and 'pulse' the newer "Pulse Secure" protocol.  For older version of
### OpenConnect that recognizes neither, specify '--protocol=juniper',
### which will results in using 'openconnect' legacy option '--juniper'.
###
### Pulse Secure GUI configuration:
### Calling 'ucsf-vpn start --method=pulse --gui' will, if missing,
### automatically add a valid VPN connection to the Pulse Secure GUI
### with the following details:
###  - Name: UCSF
###  - URL: https://remote.ucsf.edu/pulse
### You may change the name to you own liking.
###
### Troubleshooting:
### * Verify your username and password at https://remote.ucsf.edu/.
###   This should be your UCSF Active Directory ID (username); neither
###   MyAccess SFID (e.g. 'sf*****') nor UCSF email address will work.
### * If you are using the Pulse Secure client (`ucsf-vpn --method=pulse`),
###   - Make sure ports 4242 & 443 are not used by other processes
###   - Make sure 'https://remote.ucsf.edu/pulse' is used as the URL
###   - Run 'ucsf-vpn troubleshoot' to inspect the Pulse Secure logs
###
### Useful resources:
### * UCSF VPN information:
###   - https://software.ucsf.edu/content/vpn-virtual-private-network
### * UCSF Web-based VPN Interface:
###   - https://remote-vpn01.ucsf.edu/ (preferred)
###   - https://remote.ucsf.edu/
### * UCSF Two-Factory Authentication (2FA):
###   - https://it.ucsf.edu/services/duo-two-factor-authentication
### * UCSF Managing Your Passwords:
###   - https://it.ucsf.edu/services/managing-your-passwords
###
### Version: 5.8.0
### Copyright: Henrik Bengtsson (2016-2024)
### License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
### Source: https://github.com/HenrikBengtsson/ucsf-vpn
call="$0 $*"

export PULSEPATH=${PULSEPATH:-/usr/local/pulse}
export PATH="${PULSEPATH}:${PATH}"
export LD_LIBRARY_PATH="${PULSEPATH}:${LD_LIBRARY_PATH}"

this="${BASH_SOURCE%/}"; [[ -L "${this}" ]] && this=$(readlink "${this}")
incl="$(dirname "${this}")/incl"

# shellcheck source=incl/output.sh
source "${incl}/output.sh"

# shellcheck source=incl/cli.sh
source "${incl}/cli.sh"

# shellcheck source=incl/system.sh
source "${incl}/system.sh"

# shellcheck source=incl/connections.sh
source "${incl}/connections.sh"

function status() {
    local assert mcmd msg ok
    local -i pid
    local -a info
    local -a msgs
    local -a methods
    local -a connected
    local method
    local oldIFS
    local timestamp now since s m h age

    assert=$1
    mdebug "status() ..."
    mdebug "- assert='$assert'"
    mdebug "- validate='$validate'"
    minfo "validate='$validate'"

    oldIFS="$IFS"
    IFS=","
    read -ra methods <<< "$validate"
    IFS="$oldIFS"
    mdebug "- methods: [n=${#methods[@]}] ${methods[*]}"

    connected=()
    for method in "${methods[@]}"; do
        mdebug "Checking with ${method} ..."
        if [[ $method == pid ]]; then
            pid=$(openconnect_pid)
            if [[ $pid == -1 ]]; then
                connected+=(false)
                msg="No 'openconnect' process running"
            else
                connected+=(true)
                timestamp=$(ps -p "${pid}" -o lstart=)
                if [[ -n ${timestamp} ]]; then
                    timestamp=$(date -d "${timestamp}" --iso-8601=seconds)
                    since=$(date -d "${timestamp}" +%s)
                    now=$(date +%s)
		    s=$((now - since))
		    m=$((s / 60))
		    s=$((s - 60 * m))
		    h=$((m / 60))
		    m=$((m - 60 * h))
		    age=$(printf "%02dh%02dm%02ds" "${h}" "${m}"  "${s}")
                fi
                msg="'openconnect' process running (started ${age} ago on ${timestamp}; PID=${pid})"
            fi
            msgs+=("OpenConnect status: $msg")
        elif [[ $method == iproute ]]; then
            mapfile -t info < <(ip route show | grep -E "\btun[[:digit:]]?\b" | cut -d ' ' -f 3 | sort -u)
            if [[ ${#info[@]} -gt 0 ]]; then
                connected+=(true)
                msg="yes (n=${#info[@]} ${info[*]})"
            else
                connected+=(false)
                msg="none"
            fi
            msgs+=("IP routing tunnels: ${msg}")
        elif [[ $method == ipinfo ]]; then
            if is_connected; then
                connected+=(true)
            else
                connected+=(false)
            fi
            msgs+=("Public IP information: $(public_info)")
        else
            merror "Unknown --validate value: $method"
        fi
        mdebug "- connected: [n=${#connected[@]}] ${connected[*]}"
        mdebug "- msgs: [n=${#msgs[@]}] ${msgs[*]}"
        mdebug "Checking with ${method} ... done"
    done

    ## Consensus
    mapfile -t connected < <(printf "%s\n" "${connected[@]}" | sort -u)
    mdebug "- connected: [n=${#connected[@]}] ${connected[*]}"

    if [[ ${#connected[@]} -eq 1 ]]; then
        mcmd="echo"
        if [[ -n $assert ]]; then
            ok=true
            if [[ $assert == "disconnected" ]] && ${connected[0]}; then
                ok=false
            elif [[ $assert == "connected" ]] && ! ${connected[0]}; then
                ok=false
            fi
            if $ok; then
                mcmd="mok"
            else
                mcmd="merror"
            fi
        fi
        for msg in "${msgs[@]}"; do
            "$mcmd" "${msg}"
        done
        if ${connected[0]}; then
            msg="Connected to the VPN"
        else
            msg="Not connected to the VPN"
        fi
        "$mcmd" "$msg"
    else
        for msg in "${msgs[@]}"; do
            echo "${msg}"
        done
        merror "Conflicting results whether connected to the VPN. This can happen if the network dropped temporarily while on the VPN. You might be able to fix it with 'ucsf vpn restart'"
    fi

    mdebug "status() ... done"
}


# shellcheck source=incl/auth.sh
source "${incl}/auth.sh"

# shellcheck source=incl/pulse.sh
source "${incl}/pulse.sh"

# shellcheck source=incl/openconnect.sh
source "${incl}/openconnect.sh"

# -------------------------------------------------------------------------
# XDG config utility functions
# -------------------------------------------------------------------------
function xdg_state_path() {
    local path

    path=${XDG_STATE_HOME:-$HOME/.local/state}/ucsf-vpn
    if [ ! -d "$path" ]; then
        mkdir -p "$path"
    fi
    echo "$path"
}

function xdg_config_path() {
    local path

    ## https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    path=${XDG_CONFIG_HOME:-$HOME/.config}/ucsf-vpn
    if [ ! -d "$path" ]; then
        mkdir -p "$path"
    fi
    echo "$path"
}

function make_pii_file() {
    pii_cleanup
    mktemp --dry-run --tmpdir="$(xdg_state_path)" --suffix=-ipinfo.json
}

function pii_cleanup() {
    if [[ -f "$pii_file" ]]; then
         mdebug "Removing file: $pii_file"
        rm "$pii_file"
    fi
}


# Function to safely parse and set environment variables for file
function source_envs() {
    local file line key value
    
    file="$(xdg_config_path)/envs"

    ## Nothing to do?
    if [[ ! -f "${file}" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        # Skip empty lines and lines starting with #
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:blank:]]*# ]] && continue

        # Assert that line specifies a key=value pair
        if [[ ! "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*=.*$ ]]; then
            merror "Syntax error in ${file}: ${line}"
        fi

        # Split the line into key and value parts
        key="${line%%=*}"
        value="${line#*=}"

        # Resolve any variables and expressions in the value part
        eval "value=${value}"

        # Assign the resolved value to environment variable specified by the key
        export "$key=$value"
    done < "${file}"
}


function flavor_home() {
    local path file pathname
    local -i count

    ## No flavor specified
    if [[ -z ${flavor} ]]; then
        echo
        return
    fi

    path="$(xdg_config_path)/flavors/${flavor}"
    if [[ ! -d "${path}" ]]; then
        merror "Folder not found: ${path}"
    fi

    count=0
    for file in pre-connect.sh post-connect.sh; do
        pathname=${path}/${file}
        if [[ -f "${pathname}" ]]; then
            if ! bash -n "${pathname}"; then
                merror "File syntax error: ${pathname}"
            fi
            count+=1
        fi
    done

    if [[ "${count}" -eq 0 ]]; then
        merror "Flavor folder contains no known hook script files: ${path}"
    fi
    
    echo "${path}"    
}    


function logfile() {
    local path file
    
    path="$(xdg_state_path)/logs"
    if [ ! -d "$path" ]; then
        mkdir -p "$path"
    fi

    file="${path}"/ucsf-vpn.log

    ## Create log file
    touch "${file}"
    
    echo "${file}"
}


# -------------------------------------------------------------------------
# MAIN
# -------------------------------------------------------------------------
pid_file="$(xdg_state_path)/openconnect.pid"
ip_route_novpn_file="$(xdg_state_path)/ip-route.novpn.out"
ip_route_vpn_file="$(xdg_state_path)/ip-route.vpn.out"
pii_file=$(make_pii_file)

source_envs

## Actions
action=

## VPN method: 'openconnect' or 'pulse' (default)
method=${UCSF_VPN_METHOD:-openconnect}

## Options
server=${UCSF_VPN_SERVER:-remote.ucsf.edu}
url=
theme=${UCSF_VPN_THEME:-cli}
force=false
full=false
debug=false
verbose=false
validate=
dryrun=false
realm=
extras=("${UCSF_VPN_EXTRAS[@]}")
protocol=${UCSF_VPN_PROTOCOL:-nc}
gui=true
notification=false
speed=1.0
presudo=${UCSF_VPN_PRESUDO:-true}
flavor=${UCSF_VPN_FLAVOR}

## User credentials
user=
pwd=
token=${UCSF_VPN_TOKEN:-push}

# Parse command-line options
while [[ $# -gt 0 ]]; do
    mdebug "Next CLI argument: $1"

    ## Commands:
    if [[ "$1" == "start" ]]; then
        action=start
    elif [[ "$1" == "stop" ]]; then
        action=stop
    elif [[ "$1" == "toggle" ]]; then
        action=toggle
        force=true
    elif [[ "$1" == "restart" ]]; then
        action=restart
        force=true
    elif [[ "$1" == "status" ]]; then
        action=status
    elif [[ "$1" == "details" ]]; then
        action=details
    elif [[ "$1" == "routing" ]]; then
        action=routing
    elif [[ "$1" == "log" ]]; then
        action=log
    elif [[ "$1" == "troubleshoot" ]]; then
        action=troubleshoot
    elif [[ "$1" == "open-gui" ]]; then
        action=open-gui
    elif [[ "$1" == "close-gui" ]]; then
        action=close-gui

    ## Options (--flags):
    elif [[ "$1" =~ ^--[^=]*$ ]]; then
        flag=${1//--}
        if [[ "$flag" == "args" ]]; then
            # Treat all options after --args as 'extras'
            shift
            extras+=("$@")
            ## Consume all remaining options
            shift "$#"
        elif [[ "$flag" == "help" ]]; then
            action=help
        elif [[ "$flag" == "version" ]]; then
            action=version
        elif [[ "$flag" == "debug" ]]; then
            debug=true
        elif [[ "$flag" == "verbose" ]]; then
            verbose=true
        elif [[ "$flag" == "force" ]]; then
            force=true
        elif [[ "$flag" == "full" ]]; then
            full=true
        elif [[ "$flag" == "dry-run" ]]; then
            dryrun=true
        elif [[ "$flag" == "dryrun" ]]; then
            merror "Did you mean to use '--dry-run'?"
        elif [[ "$flag" == "notification" ]]; then
            notification=true
        elif [[ "$flag" == "no-notification" ]]; then
            notification=false
        elif [[ "$flag" == "gui" ]]; then
            gui=true
        elif [[ "$flag" == "no-gui" ]]; then
            gui=false
        else
            merror "Unknown option: '$1'"
        fi

    ## Options (--key=value):
    elif [[ "$1" =~ ^--.*=.*$ ]]; then
        key=${1//--}
        key=${key//=*}
        value=${1//--[[:alpha:]]*=}
        mdebug "Key-value option '$1' parsed to key='$key', value='$value'"
        if [[ -z $value ]]; then
            merror "Option '--$key' must not be empty"
        fi
        if [[ "$key" == "method" ]]; then
            method=$value
        elif [[ "$key" == "url" ]]; then
            url=$value
        elif [[ "$key" == "server" ]]; then
            server=$value
        elif [[ "$key" == "realm" ]]; then
            realm=$value
        elif [[ "$key" == "user" ]]; then
            user=$value
        elif [[ "$key" == "protocol" ]]; then
            protocol=$value
        elif [[ "$key" == "pwd" ]]; then
            pwd=$value
        elif [[ "$key" == "token" ]]; then
            token=$value
        elif [[ "$key" == "speed" ]]; then
            speed=$value
        elif [[ "$key" == "theme" ]]; then
            theme=$value
        elif [[ "$key" == "validate" ]]; then
            validate=$value
        elif [[ "$key" == "presudo" ]]; then
            if [[ $value == "true" ]]; then
                presudo=true
            elif [[ $value == "false" ]]; then
                presudo=false
            else
                merror "Unknown value --presudo=$value"
            fi
        elif [[ "$key" == "flavor" ]]; then
            flavor=$value
        else
            merror "Unknown option: '$1'"
        fi

    ## DEPRECATED: Options (--key value):
    elif [[ "$1" == "--skip" ]]; then
        mdefunct "Command-line option '$1' is defunct."
    elif [[ "$1" =~ ^--(method|pwd|realm|server|speed|token|url|user)$ ]]; then
        mdefunct "Command-line option format '$1 $2' is defunct. Use '$1=$2' instead."
    else
        merror "Unknown option: '$1'"
    fi
    shift
done


## --help should always be available prior to any validation errors
if [[ -z $action ]]; then
    help
    _exit 0
elif [[ $action == "help" ]]; then
    help full
    _exit 0
fi


## Use default URL?
[[ -z "$url" ]] && url=https://${server}/pulse


# -------------------------------------------------------------------------
# Validate options
# -------------------------------------------------------------------------
## Validate 'method'
if [[ ${method} == "openconnect" ]]; then
    mdebug "Method: $method"
elif [[ ${method} == "pulse" ]]; then
    mdebug "Method: $method"
    mwarn "Using Pulse Secure is deprecated as of ucsf-vpn 5.7.0 (2024-04-27) in favor of the default --method=openconnect. Support for --method=pulse will be removed in a near-future release."
else
    merror "Unknown value on option --method: '$method'"
fi

## Validate 'realm'
if [[ -z $realm ]]; then
    if $gui; then
        realm="Dual-Factor Pulse Clients"
    else
        realm="Single-Factor Pulse Clients"
    fi
fi
if [[ $realm == "Single-Factor Pulse Clients" ]]; then
    true
elif [[ $realm == "Dual-Factor Pulse Clients" ]]; then
    true
elif [[ $realm == "single" ]]; then
    realm="Single-Factor Pulse Clients"
elif [[ $realm == "dual" ]]; then
    realm="Dual-Factor Pulse Clients"
else
    merror "Unknown value on option --realm: '$realm'"
fi

## Validate 'token':
if [[ ${token} == "true" ]]; then  ## Backward compatibility
    token="prompt"
fi
if [[ $realm != "Dual-Factor Pulse Clients" ]]; then
    token=false
elif [[ ${token} == "prompt" || ${token} == "true" ]]; then
    mdebug "Will prompt user for 2FA token"
elif [[ ${token} == "false" ]]; then
    mdebug "Will not use 2FA authentication"
elif [[ $(type_of_token "$token") == "unknown" ]]; then
    merror "The token (--token) must be 6 or 7 digits or 44 letters (YubiKey)"
fi

## Validate 'theme'
if [[ ! $theme =~ ^(cli|none)$ ]]; then
    merror "Unknown --theme value: '$theme'"
fi

## Validate 'validate'
if [[ $method == "openconnect" ]]; then
    if [[ -z $validate ]]; then
        validate=${UCSF_VPN_VALIDATE:-pid,iproute,ipinfo}
    fi
elif [[ $method == "pulse" ]]; then
    if [[ -z $validate ]]; then
        validate=${UCSF_VPN_VALIDATE:-ipinfo}
    elif [[ ! $validate =~ ^(ipinfo)$ ]]; then
        merror "Unknown --validate value: '$validate'"
    fi
fi

## Validate 'speed'
if [[ ! ${speed} =~ ^[0-9]+[.0-9]*$ ]]; then
    merror "Invalid --speed argument: '$speed'"
fi


# -------------------------------------------------------------------------
# Initiate
# -------------------------------------------------------------------------
## Regular expression for locating the proper netrc entry
if [[ "$server" == "remote.ucsf.edu" ]]; then
    netrc_machines=${server}
else
    netrc_machines=("${server}" remote.ucsf.edu)
fi

mdebug "call: $call"
mdebug "action: $action"
mdebug "VPN server: $server"
mdebug "Realm: '$realm'"
mdebug "protocol: $protocol"
mdebug "user: $user"
if [[ -z "${pwd}" ]]; then
    mdebug "pwd=<missing>"
else
    mdebug "pwd=<hidden>"
fi
if [[ -z "${token}" ]]; then
    mdebug "token=<missing>"
elif [[ $token == "prompt" ]]; then
    mdebug "token=<prompt>"
elif [[ $token == "push" || $token == "sms" || $token =~ ^phone[1-9]*$ ]]; then
    mdebug "token=$token"
else
    mdebug "token=<hidden>"
fi
mdebug "verbose: $verbose"
mdebug "force: $force"
mdebug "validate: $validate"
mdebug "dryrun: $dryrun"
mdebug "extras: [n=${#extras[@]}] ${extras[*]}"
mdebug "method: $method"
mdebug "gui: $gui"
mdebug "speed: $speed"
mdebug "netrc_machines: ${netrc_machines[*]}"
mdebug "pid_file: $pid_file"
mdebug "openconnect_pid: $(openconnect_pid)"
mdebug "pii_file: $pii_file"


# -------------------------------------------------------------------------
# Actions
# -------------------------------------------------------------------------
if [[ $action == "version" ]]; then
    if $full; then
        echo "ucsf-vpn $(version)"
        echo "OpenConnect $(openconnect_version)"
    else
        version
    fi
    _exit 0
fi

if [[ $action == "status" ]]; then
    status
elif [[ $action == "details" ]]; then
    connection_details
    _exit $?
elif [[ $action == "routing" ]]; then
    routing_details
    _exit $?
elif [[ $action == "open-gui" ]]; then
    if [[ $method != "pulse" ]]; then
        merror "ucsf vpn open-gui requires --method=pulse: $method"
    fi
    pulse_open_gui
    res=$?
    _exit $res
elif [[ $action == "close-gui" ]]; then
    if [[ $method != "pulse" ]]; then
        merror "ucsf vpn open-gui requires --method=pulse: $method"
    fi
    pulse_close_gui
    res=$?
    _exit $res
elif [[ $action == "start" ]]; then
    if [[ $method == "openconnect" ]]; then
        openconnect_start
        res=$?
    elif [[ $method == "pulse" ]]; then
        pulse_start
        res=$?
        sleep "$(div 4.0 "$speed")"
    fi
    status "connected"
elif [[ $action == "stop" ]]; then
    if [[ $method == "openconnect" ]]; then
        openconnect_stop
        res=$?
    elif [[ $method == "pulse" ]]; then
        pulse_stop
        res=$?
        sleep "$(div 1.0 "$speed")"
    fi
    status "disconnected"
elif [[ $action == "restart" ]]; then
    if [[ $method == "openconnect" ]]; then
        if $force || is_connected; then
            openconnect_stop
        fi
        openconnect_start
        res=$?
    elif [[ $method == "pulse" ]]; then
        pulse_stop
        sleep "$(div 1.0 "$speed")"
        is_online
        pulse_start
        sleep "$(div 4.0 "$speed")"
        res=$?
    fi
    status "connected"
elif [[ $action == "toggle" ]]; then
    if ! is_connected; then
      if [[ $method == "openconnect" ]]; then
          openconnect_start
      elif [[ $method == "pulse" ]]; then
          pulse_start
          sleep "$(div 4.0 "$speed")"
      fi
      status "connected"
    else
      if [[ $method == "openconnect" ]]; then
          openconnect_stop
      elif [[ $method == "pulse" ]]; then
          pulse_stop
          sleep "$(div 1.0 "$speed")"
      fi
      status "disconnected"
    fi
elif [[ $action == "log" ]]; then
    if [[ $method == "openconnect" ]]; then
        LOGFILE=/var/log/syslog
        minfo "Displaying 'VPN' entries in log file: $LOGFILE"
        if [[ ! -f $LOGFILE ]]; then
            mwarn "No such log file: $LOGFILE"
            _exit 1
        fi
        grep VPN "$LOGFILE"
    elif [[ $method == "pulse" ]]; then
        LOGFILE=$HOME/.pulse_secure/pulse/pulsesvc.log
        minfo "Displaying log file: $LOGFILE"
        if [[ ! -f $LOGFILE ]]; then
            mwarn "No such log file: $LOGFILE"
            _exit 1
        fi
        cat "$LOGFILE"
    fi
elif [[ $action == "troubleshoot" ]]; then
    if [[ $method == "openconnect" ]]; then
        merror "ucsf-vpn troubleshoot is not implemented for --method=openconnect"
    elif [[ $method == "pulse" ]]; then
        pulse_troubleshoot
    fi
fi


_exit 0
