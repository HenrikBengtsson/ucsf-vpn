2017-12-07: Two-factor authentication (2FA) is now required to connect to the UCSF VPN.  As it stands now, `ucsf-vpn start` no longer works and you need to use the GUI-version `ucsf-vpn start-gui` instead, which means enter your credentials (each time) and 2FA passcode in two different HTML popup windows.

If anyone can figure out a solution for passing also the 2FA passcode via the Pulse command-line client, please drop a note in the [issue tracker](https://github.com/HenrikBengtsson/ucsf-vpn/issues).  Then we could do things such as `ucsf-vpn start <passcode>`.  Even just passing the user credentials and then enter the 2FA passcode in a HTML-popup panel would help.

