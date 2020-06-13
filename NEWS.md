ucsf-vpn
========

## Version 5.2.0-9000 (2020-06-13)

 * ...
 

## Version 5.2.0 (2020-06-13)

### New Features

 * An informative message prompts the users what additional action needs
   to be done whenever `--token=push` or `--token=phone` is used.

 * If the connection fails, the likely reason for the failure is now given as
   part of the error message, e.g. 'Incorrect username or password' or
   '2FA token not accepted'.

 * The verbose standard error messages from OpenConnect is only displayed
   if the connected fails, otherwise it is muffled.

 * Error messages now include the version of ucsf-vpn and OpenConnect.

 * Environment variable `UCSF_VPN_PING_SERVER` now supports specifying
   multiple servers (separated by space).
   
 * The default ping server is now 9.9.9.9 (Quad9.net).
 

## Version 5.1.0 (2020-03-24)

### New Features

 * The server used for testing the internet connection by pinging it, can
   now be controlled by environment variable `UCSF_VPN_PING_SERVER`.
 
 * The prompt asking for type of token now echoes type of token requested.

 * If OpenConnect requires additional options, then these can be specified
   also via environment variable `UCSF_VPN_EXTRAS`.

 * The validation toward the third-party https://ipinfo.io/ service done by
   `ucsf-vpn status`, `ucsf-vpn start` and `ucsf-vpn stop` can be disabled
   by specifying option `--validate=pid`, or by setting environment variable
   `UCSF_VPN_VALIDATE=pid`.

 * Sudo rights are now established upfront with an informative message.

### Bug Fixes

 * It was not possible to pass additional options of kind `--key value` to
   the `openconnect` client; they were dropped with an incorrect warning on
   using `--key=value` instead.
 

## Version 5.0.0 (2020-03-20)

### Significant changes

 * `ucsf-vpn start` and `ucsf-vpn stop` is significantly faster because in
   previous versions there was a bug (see below) causing it to query for
   public IP information multiple times, which was slow.

 * Now supporting proper key-value pair CLI options, e.g. `--user=alice`.
 
### New Features

 * `ucsf-vpn stop` makes sure to terminate the process that `ucsf-vpn start`
   started, which works by having OpenConnect record the process ID to file.
   Previously, `ucsf-vpn stop` terminated _all_ `openconnect` process found.

 * Messages are now outputted in different colors if the terminal supports it.
   Success message are outputted in green, warnings in yellow, errors in red,
   and debug messages in gray.  Message from OpenConnect are outputted using
   the default foreground color, which is typically white.  Similarly, prompts
   are highlighted in bright yellow.  Disable with `--theme=none` or set
   environment variable `UCSF_VPN_THEME=none`.

 * Now `ucsf-vpn` displays parts of the help and `ucsf-vpn --help` the full.

### Bug Fixes

 * `ucsf-vpn` failed to cache collected public IP information resulting in
   it queried the same public IP information multiple times.

### Deprecated

 * Legacy, non-standard key-value pair CLI options without equal signs such
   as `--user alice` are now deprecated. Use `--user=alice` instead.

 * CLI option `--skip` has been dropped.  It is now the default behavior.
 

## Version 4.3.0 (2020-03-16)

### New Features

 * The VPN server can now be set via environment variable `UCSF_VPN_SERVER` as
   an alternative to specifying option `--server`. `ucsf-vpn start` will output
   'Connection to server <server> ...' to indicate which server is used.

 * If a custom VPN server is used, then the ~/.netrc file is search for that
   first with a fallback to 'remote.ucsf.edu'.  This avoids having to update
   the .netrc file when using an alternative UCSF-VPN server.

 

## Version 4.2.0 (2019-10-15)

### New Features

 * Updated how the information on the current connection is reported by
   for instance `ucsf-vpn status`.

### Bug Fixes

 * The reported IP could be garbled with a newline and 'https'.
 

## Version 4.1.0 (2019-05-15)

### New Features

 * Attempts to connect using `--token sms` will now give an informative error
   message explaining that is not supported by the OpenConnect interface.

### Bug Fixes

 * `ucsf-vpn --token <digits>` only supported six-digit tokens; now seven-digit
   tokens are also supported.
   

## Version 4.0.0 (2018-07-31)

### Significant Changes

 * The default VPN method is now OpenConnect (`--method openconnect`).  The
   previous method, Pulse Secure Client, is available by using `--method pulse`.

 * The default is now `--token push` (was `--token prompt`).
   
### New Features

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

### Bug Fixes

 * Option `--token` did not have a default value.

### Deprecated & Defunct

 * Option `--token true` is deprecated; use `--token prompt` instead.

 * Credentials in ~/.ucsfvpnrc are now ignored. Use ~/.netrc instead.
 

## Version 3.2.1 (2018-01-04)

### New Features

 * Now `ucsf-vpn start --gui` gives more information about the steps
   taken and how to force or skip a UCSF notification popup, if such
   exists (which they add once in a while to notify users).

 * Now `ucsf-vpn start --gui` defaults to `--no-notification`, since
   UCSF has now removed the notification about the new 2FA requirements.


## Version 3.2.0 (2017-12-14)

### New Features

 * Now `ucsf-vpn start --gui` looks in the Pulse Secure GUI config file
   to identify which of several connections is for the target VPN URL.
   If none matches, a proper connection is automatically added to the
   settings.
   
 * Add option `--url <url>` for specifying the VPN URL.  Currently, only
   used for validation.

 * Now `--realm <realm>` is acknowledged also for `--gui` (though UCSF VPN
   still only 'Dual Factor Pulse Clients').

 * Now `ucsf-vpn troubleshoot` reports on the configured connections
   available in the Pulse Secure GUI.  If a connection to the UCSF-specific
   VPN URL is missing, then a warning is displayed.

 * The default value for `--token` can be set via env var `UCSF_VPN_TOKEN`.


## Version 3.1.1 (2017-12-12)
 
SOFTWARE QUALITY:

 * Fixed Bash code according to ShellCheck suggestions.

 * Running ShellCheck code analysis via Travis CI.
 

## Version 3.1.0 (2017-12-09)

### New Features

 * Added support for `--token push` and `--token phone`, which will
   authenticate via the Duo app (approve and confirm), and phone call
   ("press any key"), respectively.  Also, accepts `--token phone2`,
   and `--token sms` but not sure the UCSF supports those.

 * Now `ucsf-vpn start --gui` minimizes the main Pulse Secure GUI window
   as soon as it is no longer needed.

 * Now `ucsf-vpn start --gui` waits for the popup windows to close before
   verifying that the VPN connection is working.

### Bug Fixes

 * `ucsf-vpn start --gui` would not works if Pulse Secure GUI was already
   open but minimized.

 * `ucsf-vpn stop` failed to close the Pulse Secure GUI window.


## Version 3.0.0 (2017-12-09)

### Significant Changes

 * Two-factor authentication (2FA) is now supported by sending user credentials
   and 2FA tokens via the Pulse Secure GUI by utilizing xdotool (automated
   mouse clicks and key presses over X11).  It's not perfect, but it works.
 
 * Now `ucsf-vpn start --gui` is the default.

 * `ucsf-vpn start-gui` was renamed to `ucsf-vpn open-gui`.

### New Features

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

 * Use environment variable `PULSEPATH` to override the default location
   (/usr/local/pulse/) of the Pulse Secure software and libraries.

### Deprecated & Defunct

 * Credentials in ~/.ucsfvpnrc are defunct. Use ~/.netrc instead.

 
## Version 2.3.0 (2017-12-08)

### New Features

 * Added `ucsf-vpn log`, which output the log file.
 
 * Added `ucsf-vpn troubleshoot`, which reports on errors in the log file.

### Bug Fixes

 * Authentication credentials in ~/.netrc were not found on systems where
   where awk does not support POSIX regular expressions.
   

## Version 2.2.0 (2017-11-10)

### New Features

 * If username and/or password are not specified or not identifiable from
   the ~/.netrc file, then the user will be prompted to enter them.
 

## Version 2.1.0 (2017-11-04)

### Significant Changes

 * Add support for credentials in ~/.netrc.

### Deprecated & Defunct

 * Credentials in ~/.ucsfvpnrc are deprecated. Use ~/.netrc instead.


## Version 2.0.0 (2017-11-03)

### Significant Changes

 * Now supporting the new Junos Secure Pulse client.

### Deprecated & Defunct

 * Support for OpenConnect is defunct due to UCSF VPN server changes.
 

## Version 1.3.0 (2017-02-16)

### New Features

 * Add option `--server <server>` to override the default VPN specify.

 * `ucsf-vpn --help` reports on the OpenConnect version available.


## Version 1.2.0 (2016-10-14)

### New Features

 * Add `ucsf-vpn toggle` for quick toggling of the UCSF VPN connect.


## Version 1.1.0 (2016-09-25)

### New Features

 * Now `ucsf-vpn` checks for working internet connection and
   adjust accordingly.  For instance, `ucsf-vpn restart` will not
   try to infer public IP number if there is no internet connection
   but instead it will just go ahead an restart the local VPN service.
   
 * Add `ucsf-vpn restart`.


## Version 1.0.0 (2016-09-02)

 * First public release.
