ucsf-vpn
========

## Version 4.2.0-9000 (2020-03-04)

 * ...
 

## Version 4.2.0 (2019-10-15)

NEW FEATURES:

 * Updated how the information on the current connection is reported by
   for instance 'ucsf vpn status'.

BUG FIXES:

 * The reported IP could be garbled with a newline and 'https'.
 

## Version 4.1.0 (2019-05-15)

NEW FEATURES:

 * Attempts to connect using `--token sms` will now give an informative error
   message explaining that is not supported by the OpenConnect interface.

BUG FIXES:

 * `ucsf vpn --token <digits>` only supported six-digit tokens; now seven-digit
   tokens are also supported.
   

## Version 4.0.0 (2018-07-31)

SIGNIFICANT CHANGES:

 * The default VPN method is now OpenConnect (`--method openconnect`).  The
   previous method, Pulse Secure Client, is available by using `--method pulse`.

 * The default is now `--token push` (was `--token prompt`).
   
NEW FEATURES:

 * Added support to connect to the UCSF VPN using OpenConnect (>= 7.08),
   which is available on recent Linux distributions such as Ubuntu 18.04.
   The advantage of using OpenConnect rather that the Pulse Secure Client,
   is in addition of not requiring a proprietary software, it is also more
   stable because it does not operate by emulating key and mouse clicks in
   a GUI.  The disadvantage is that it requires sudo, i.e. you need to have
   admin rights.

 * Added option `--method` to control whether to use OpenConnect (`openconnect`)
   or the Pulse Secure Client (`pulse`).  The default, which is `openconnect`,
   can be controlled via environment variable `UCSF_VPN_METHOD`.

BUG FIXES:

 * Option `--token` did not have a default value.

DEPRECATED & DEFUNCT:

 * Option `--token true` is deprecated; use `--token prompt` instead.

 * Credentials in ~/.ucsfvpnrc are now ignored. Use ~/.netrc instead.
 

## Version 3.2.1 (2018-01-04)

NEW FEATURES:

 * Now `ucsf vpn start --gui` gives more information about the steps
   taken and how to force or skip a UCSF notification popup, if such
   exists (which they add once in a while to notify users).

 * Now `ucsf vpn start --gui` defaults to `--no-notification`, since
   UCSF has now removed the notification about the new 2FA requirements.


## Version 3.2.0 (2017-12-14)

NEW FEATURES:

 * Now `ucsf vpn start --gui` looks in the Pulse Secure GUI config file
   to identify which of several connections is for the target VPN URL.
   If none matches, a proper connection is automatically added to the
   settings.
   
 * Add option `--url <url>` for specifying the VPN URL.  Currently, only
   used for validation.

 * Now `--realm <realm>` is acknowledged also for `--gui` (though UCSF VPN
   still only 'Dual Factor Pulse Clients').

 * Now `ucsf vpn troubleshoot` reports on the configured connections
   available in the Pulse Secure GUI.  If a connection to the UCSF-specific
   VPN URL is missing, then a warning is displayed.

 * The default value for `--token` can be set via env var `UCSF_VPN_TOKEN`.


## Version 3.1.1 (2017-12-12)
 
SOFTWARE QUALITY:

 * Fixed Bash code according to ShellCheck suggestions.

 * Running ShellCheck code analysis via Travis CI.
 

## Version 3.1.0 (2017-12-09)

NEW FEATURES:

 * Added support for `--token push` and `--token phone`, which will
   authenticate via the Duo app (approve and confirm), and phone call
   ("press any key"), respectively.  Also, accepts `--token phone2`,
   and `--token sms` but not sure the UCSF supports those.

 * Now `ucsf-vpn start --gui` minimizes the main Pulse Secure GUI window
   as soon as it is no longer needed.

 * Now `ucsf-vpn start --gui` waits for the popup windows to close before
   verifying that the VPN connection is working.

BUG FIXES:

 * `ucsf-vpn start --gui` would not works if Pulse Secure GUI was already
   open but minimized.

 * `ucsf-vpn stop` failed to close the Pulse Secure GUI window.


## Version 3.0.0 (2017-12-09)

SIGNIFICANT CHANGES:

 * Two-factor authentication (2FA) is now supported by sending user credentials
   and 2FA tokens via the Pulse Secure GUI by utilizing xdotool (automated
   mouse clicks and key presses over X11).  It's not perfect, but it works.
 
 * Now `ucsf-vpn start --gui` is the default.

 * `ucsf-vpn start-gui` was renamed to `ucsf-vpn open-gui`.

NEW FEATURES:

 * Now `ucsf-vpn start` (with default `--gui`) connects to the UCSF VPN
   via the Pulse Secure GUI (by sending mouse and key sequences).

 * Added `--gui` (default) and `--no-gui` to control whether `ucsf-vpn start`
   should the Pulse Secure GUI or the CLI.

 * Added `--token <token>` to specify the one-time two-factor authentication
   (2FA) token, where `--token true` (default) will prompt user to enter
   token, and `--token false` will try to connect without 2FA.

 * Added `--notification` (default) and `--no-notification` to indicate
   whether the UCSF VPN login includes a "Pre Sign-In Notification" message
   that needs to be confirmed or not.
  
 * Added `--speed <factor>` for adjusting the waiting times between
   submitting information to the GUI.

 * Now `ucsf-vpn troubleshoot` also reports on `pulsesvc --version`.

 * Use environment variable PULSEPATH to override the default location
   (/usr/local/pulse/) of the Pulse Secure software and libraries.

DEPRECATED & DEFUNCT:

 * Credentials in ~/.ucsfvpnrc are defunct. Use ~/.netrc instead.

 
## Version 2.3.0 (2017-12-08)

NEW FEATURES:

 * Added `ucsf-vpn log`, which output the log file.
 
 * Added `ucsf-vpn troubleshoot`, which reports on errors in the log file.

BUG FIXES:

 * Authentication credentials in ~/.netrc were not found on systems where
   where awk does not support POSIX regular expressions.
   

## Version 2.2.0 (2017-11-10)

NEW FEATURES:

 * If username and/or password are not specified or not identifiable from
   the ~/.netrc file, then the user will be prompted to enter them.
 

## Version 2.1.0 (2017-11-04)

SIGNIFICANT CHANGES:

 * Add support for credentials in ~/.netrc.

DEPRECATED & DEFUNCT:

 * Credentials in ~/.ucsfvpnrc are deprecated. Use ~/.netrc instead.


## Version 2.0.0 (2017-11-03)

SIGNIFICANT CHANGES:

 * Now supporting the new Junos Secure Pulse client.

DEPRECATED & DEFUNCT:

 * Support for OpenConnect is defunct due to UCSF VPN server changes.
 

## Version 1.3.0 (2017-02-16)

NEW FEATURES:

 * Add option `--server <server>` to override the default VPN specify.

 * `ucsf-vpn --help` reports on the OpenConnect version available.


## Version 1.2.0 (2016-10-14)

NEW FEATURES:

 * Add `ucsf-vpn toggle` for quick toggling of the UCSF VPN connect.


## Version 1.1.0 (2016-09-25)

NEW FEATURES:

 * Now `ucsf-vpn` checks for working internet connection and
   adjust accordingly.  For instance, `ucsf-vpn restart` will not
   try to infer public IP number if there is no internet connection
   but instead it will just go ahead an restart the local VPN service.
   
 * Add `ucsf-vpn restart`.


## Version 1.0.0 (2016-09-02)

 * First public release.
