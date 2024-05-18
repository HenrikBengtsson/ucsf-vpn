#!/bin/sh
####################################################################
# Use user-specific UCSF VPN configurations
#
# Install:
#   mkdir -p /etc/vpnc/connect.d/
#   cp ucsf-vpn-flavors.sh /etc/vpnc/connect.d/
#
# Requires:
#   https://github.com/HenrikBengtsson/ucsf-vpn
####################################################################

## Called via 'ucsf-vpn'?
if [ -n "${UCSF_VPN_VERSION}" ]; then
    ucsf_vpn_log() {
       echo "[$(date --iso-8601=seconds)] $*" >> "${UCSF_VPN_LOGFILE}"
    }

    ucsf_vpn_log "$* ..."
    ucsf_vpn_log "UCSF_VPN_VERSION=${UCSF_VPN_VERSION}"
    ucsf_vpn_log "UCSF_VPN_FLAVOR=${UCSF_VPN_FLAVOR}"

    if [ "$1" = "connect" ]; then
        _hook_="pre-connect"
    else
        _hook_="$1"
    fi
    ucsf_vpn_log "hook=${_hook_}"

    _hook_file_="${UCSF_VPN_FLAVOR}/${_hook_}.sh"
    ucsf_vpn_log "${_hook_file_} ..."
    if [ -f "${_hook_file_}" ]; then
        _hook_status_="done"

        # shellcheck disable=SC1090
        . "${_hook_file_}" || _hook_status_="error"
        
        ucsf_vpn_log "${_hook_file_} ... ${_hook_status_}"
    else
        ucsf_vpn_log "${_hook_file_} ... non-existing"
    fi
    
    ucsf_vpn_log "$* ... done"
fi
