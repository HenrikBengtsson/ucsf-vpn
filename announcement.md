2019-05-15: (ucsf-vpn 4.1.0) 

2018-07-31: (ucsf-vpn 4.0.0) Added support for OpenConnect (>= 7.08), which is the new default.  If you have an older version of OpenConnect (`openconnect --version`), your option is to use the Pulse Secure Client by adding option `--method pulse` or setting environment variable `USCF_VPN_METHOD=pulse`.

2018-01-04: (ucsf-vpn 3.2.1) UCSF has removed their notification popup about the new 2FA requirements. I've updated `ucsf-vpn start` to use `--no-notification` by default.

2017-12-09: (ucsf-vpn 3.1.0) `ucsf-vpn start` will now prompt for the 2FA token (Duo or YubiKey) and then submit user credentials and the 2FA token via the Pulse Secure GUI.

2017-12-07: Two-factor authentication (2FA) is now required in order to connect to the UCSF VPN.

