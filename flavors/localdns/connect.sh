#!/bin/sh
####################################################################
# Tunnel only UCSF intranet
#
# Install:
#   mkdir -p ~/.config/ucsf-vpn/flavors/localdns/
#   cp connect.sh ~/.config/ucsf-vpn/flavors/localdns/
# 
# Requires:
#   https://github.com/HenrikBengtsson/ucsf-vpn
#
# Description:
#   This script overrides parts of the default behavior of
#   /usr/share/vpnc-scripts/vpnc-script. It's been verified to
#   to work on Ubuntu 22.04.
#
# Authors: Henrik Bengtsson
# Version: 2024-05-22
# License: GPL
####################################################################

#-------------------------------------------------------------------
# Tweak DNS lookup
#-------------------------------------------------------------------
# Tricks modify_resolvconf_generic() to prepend the local nameserver
# before the ones that the VPN server provides.
_nameservers_=$(grep "^nameserver[[:blank:]]" /etc/resolv.conf | sed -E 's/nameserver[[:blank:]]+//')
INTERNAL_IP4_DNS="${_nameservers_} $INTERNAL_IP4_DNS"
