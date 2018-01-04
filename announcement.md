2018-01-04: UCSF has removed their notification popup about the new 2FA requirements. I've updated `ucsf-vpn start` to use `--no-notification` by default.

2017-12-09: `ucsf-vpn start` will now prompt for the 2FA token (Duo or YubiKey) and then submit user credentials and the 2FA token via the Pulse Secure GUI.

2017-12-07: Two-factor authentication (2FA) is now required in order to connect to the UCSF VPN.

If anyone can figure out a solution for passing also the 2FA passcode via the Pulse command-line client, please drop a note in the [issue tracker](https://github.com/HenrikBengtsson/ucsf-vpn/issues).

