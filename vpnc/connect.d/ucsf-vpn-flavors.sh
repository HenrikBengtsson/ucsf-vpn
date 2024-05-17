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
    file="${UCSF_VPN_FLAVOR}"/connect.sh
    if [ -f "${file}" ]; then
        . "${file}"
    fi
fi
