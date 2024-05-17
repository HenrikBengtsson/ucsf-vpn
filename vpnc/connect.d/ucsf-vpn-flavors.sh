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
       echo "[$(date --iso-8601=seconds)] $@" >> "${UCSF_VPN_LOGFILE}"
    }

    _hook_file_="${UCSF_VPN_FLAVOR}"/pre-connect.sh
    if [ -f "${_hook_file_}" ]; then
        ucsf_vpn_log "${_hook_file_} ..."
        _hook_status_="done"
        . "${_hook_file_}" || _hook_status_="error"
        ucsf_vpn_log "${_hook_file_} ... ${_hook_status_}"
    fi
fi
