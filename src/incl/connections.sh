# -------------------------------------------------------------------------
# Connection, e.g. checking whether connected to the VPN or not
# -------------------------------------------------------------------------
function ucsf_it_network_info() {
    curl --silent https://help.ucsf.edu/HelpApps/ipNetVerify.php | grep -E "<td>(Connected to UCSF Network|IP Address|Network Location)</td>" | sed 's/<\/td><td>/=/' | sed -E 's/<[^>]+>//g' | sed 's/.*Connected to UCSF Network/connected/' | sed 's/.*IP Address/public_ip/' | sed 's/.*Network Location/network/' | sed 's/=No/=false/' | sed 's/=Yes/=true/' | sed -E "s/network=(.*)/network='\1'/" | sort
}

function connection_details() {
    mdebug "connection_details()"
    if [[ ! -f "$pii_file" ]]; then
        if ! is_online; then
            merror "Internet connection is not working"
        fi
        minfo "Verified that internet connection works"
        minfo "Getting public IP (from https://ipinfo.io/ip)"
        mdebug "Calling: curl --silent  --connect-timeout 3.0 https://ipinfo.io/json > \"$pii_file\""
        if ! curl --silent --connect-timeout 3.0 https://ipinfo.io/json > "$pii_file"; then
            rm "$pii_file"
        fi
        if [[ ! -f "$pii_file" ]]; then
            merror "Failed to get public IP (from https://ipinfo.io/ip)"
        fi
        mdebug "Public connection information: $(tr -d $'\n' < "$pii_file" | sed 's/  / /g')"
    fi
    cat "$pii_file"
    echo
}

function routing_details() {
    local -a ip_route info
    local ip
    local -i kk
    local use_dig=true
    local use_whois=true

    mdebug "routing_details()"
    
    if $full; then
        command -v dig &> /dev/null || use_dig=false
        mdebug "Command 'dig' available: ${use_dig}"

        command -v whois &> /dev/null || use_whois=false
        mdebug "Command 'whois' available: ${use_whois}"
        
        if ! $use_dig && ! $use_whois; then
           mwarn "Cannot annotate IP addresses (--full). Install 'dig' or 'whois' to fix this"
        fi
    else
        use_dig=false
        use_whois=false
    fi
    
    echo "Default non-VPN network interface: $(ip_route_novpn_interface)"
    mapfile -t info < <(ip route show | grep -E "\btun[[:digit:]]?\b" | cut -d ' ' -f 3 | sort -u)
    if [[ ${#info[@]} -gt 0 ]]; then
        echo "Tunnel interfaces: [n=${#info[@]}] ${info[*]}"
    else
        echo "Tunnel interfaces: none"
    fi

    echo
    echo "Nameserve configuration (/etc/resolv.conf):"
    grep -v -E "^[[:space:]]*(#|$)" /etc/resolv.conf

    mapfile -t ip_route < <(ip route show)
    echo
    echo "IP routing table (ip route show) [${#ip_route[@]} entries]:"
    for kk in "${!ip_route[@]}"; do
        row="${ip_route[${kk}]}"
        if $use_dig || $use_whois; then
            if grep -q -E "^([[:digit:].]+).*" <<< "${row}"; then
                ip=$(sed -E 's/^([[:digit:].]+).*/\1/' <<< "${row}")
                mapfile -t info < <(
                    if $use_dig; then
                        dig -x "${ip}" +short | grep -vF "/" | sed -E 's/[.]$//'
                    fi
                    if $use_whois; then
                        whois "${ip}" | grep -i -E "^(country|netname|orgname):" | sed -E 's/^([[:alpha:]]+):[[:space:]]+/\1=/I' | sort | uniq # | sed -i -E 's/^(netname|orgname):[[:space:]]+//I'
                    fi
                )
                if [[ ${#info[@]} -gt 0 ]]; then
                    row="${row}[$(printf "%s; " "${info[@]}" | sed -E 's/; $//')]"
                fi
            fi
        fi
        echo "${row}"
    done
}

function public_ip() {
    mdebug "public_ip()"
    connection_details | grep -F '"ip":' | sed -E 's/[ ",]//g' | cut -d : -f 2
}

function public_hostname() {
    mdebug "public_hostname()"
    connection_details | grep -F '"hostname":' | sed -E 's/[ ",]//g' | cut -d : -f 2
}

function public_org() {
    mdebug "public_org()"
    connection_details | grep -F '"org":' | cut -d : -f 2 | sed -E 's/(^[ ]*"|",[ ]*$)//g'
}

function public_info() {
    local ip hostname org

    mdebug "public_info()"
    ip=$(public_ip 2> /dev/null)
    if [[ -n "${ip}" ]]; then
        hostname=$(public_hostname)
        org=$(public_org)
        printf "ip=%s, hostname='%s', org='%s'" "$ip" "$hostname" "$org"
    else
        printf "<failed to infer information>"
    fi
}

function is_online() {
    local ping_server ping_servers ping_timeout

    ping_servers=${UCSF_VPN_PING_SERVER:-${1:-9.9.9.9}}
    mdebug "Ping servers: [n=${#ping_servers}]: $ping_servers"
    ping_timeout=${UCSF_VPN_PING_TIMEOUT:-1.0}
    mdebug "Ping timeout (in seconds): $ping_timeout"
    for ping_server in $ping_servers; do
      mdebug "Ping server: '$ping_server'"
      minfo "Pinging '$ping_server' once"
      if ping -c 1 -W "$ping_timeout" "$ping_server" > /dev/null 2> /dev/null; then
          return 0
      fi
    done
    return 1
}

function is_connected() {
    mdebug "is_connected()"
    ## NOTE: It appears that field 'hostname' is not always returned, e.g. when
    ## calling it multiple times in a row some calls done report that field.
    ## Because of this, we test the status on the field 'org' instead.
    connection_details | grep -q -E "org.*[:].*AS5653 University of California San Francisco"
}


function ip_route_novpn_interface() {
    mdebug "ip_route_novpn_interface()"
    ip route show | grep -E "^default " | grep -vF " tun" | cut -d ' ' -f 5
}


function wait_for_ip_route_tunnel() {
    local -i max_iter
    mdebug "Wait for tunnel to appear in IP routing table"
    max_iter=100 ## Wait for up to 10 seconds
    while ! grep -q -E 'tun[[:digit:]]' <<< "$(ip route show)"; do
        max_iter=$((max_iter - 1))
        if [[ ${max_iter} -eq 0 ]]; then
            merror "The VPN tunnel never appeared in the IP routing table:$(echo; ip route show; echo)"
        fi
        sleep 0.1
    done
}

function wait_for_ip_route() {
    local prev curr
    
    mdebug "Wait for IP routing table to stabilize"
    prev=$(ip route show)
    curr=""
    while [[ "${curr}" != "${prev}" ]]; do
        sleep 0.5
        prev="${curr}"
        curr=$(ip route show)
    done
}
