ucsf-vpn
========

## Version 6.1.0 (2024-06-26)

### Significant changes

 * Now `ucsf vpn` validates the VPN connection using a UCSF IT web
   service hosted under `*.ucsf.edu`. Previously
   <https://ipinfo.io/ip> was the default method.  Note that `ucsf vpn
   details` still uses ipinfo.io.
 
### New Features

 * Now `ucsf vpn start --flavor=none` sets the default flavor. This
   can be used to override environment variable `UCSF_VPN_FLAVOR`,
   which may be preset in for instance `~/.config/ucsf-vpn/envs`.
 
 * Now `ucsf vpn routing` reports also on nameserver settings.

 * Now `ucsf vpn start --debug` and `ucsf vpn stop --debug` reports on
   changes to your nameserver settings (`/etc/resolv.conf`).

 * Add support for `ucsf vpn status --validate=ucsfit`, which infers
   VPN status from <https://help.ucsf.edu/HelpApps/ipNetVerify.php>.


## Version 6.0.0 (2024-05-20)

### Significant changes

 * OpenConnect is now the only supported method. Support for Pulse
   Secure GUI client has been dropped.

### New Features

 * Now `ucsf vpn start --flavor=<flavor>` checks if required
   OpenConnect hook scripts are installed on the system. If not, it
   will prompt the user if they should be installed.
   
 * Add `ucsf vpn reconnect`, which signals `SIGUSR2` to the
   OpenConnect process and thereby "forces an immediate disconnection
   and reconnection; this can be used to quickly recover from LAN IP
   address changes."

### Deprecated and Defunct

 * The use of `--method=pulse`, which uses the Pulse Secure GUI client
   to establish a VPN connection, is defunct.


## Version 5.8.0 (2024-05-18)

### Significant changes

 * Now `ucsf vpn status` uses all validation methods to conclude
   whether there is a working VPN connection or not. If they do not
   agree, an informative error is produced. Previously, it returned
   after the first validation method was successful, ignoring the
   remaining validation methods.

 * Now `ucsf vpn start` finds the logged in user's `~/.netrc` file
   also when called via `sudo`.
 
### New Features

 * Now `ucsf vpn start` and `ucsf vpn stop` wait for the updating of
   the IP routing table (`ip route show`) to finish before returning.
 
 * Now `ucsf vpn start --debug` and `ucsf vpn stop --debug` reports on
   changes to your IP routing table (per `ip route show`).

 * Now `ucsf vpn status` reports also on how long ago and when the
   OpenConnect process was started, if it exists. It also reports on
   any IP routing tunnel devices.
 
 * Now `--args` causes all of the following options to be passed to
   `openconnect`, e.g. `ucsf vpn start --args
   --script=$PWD/my-vpnc-script` causes `--script=$PWD/my-vpnc-script`
   to be passed to `openconnect`.

 * Use `--presudo=false` to skip establishing 'sudo' permissions
   upfront. The default is `--presudo=true`, which might add a `sudo:
   ... a password is required` event in the `/var/log/auth.log` log
   file, which in turn might trigger an security alert.  The default
   can be controlled via environment variable `UCSF_VPN_PRESUDO`.

 * `ucsf vpn` sources `~/.config/ucsf-vpn/envs` on start, which
   provides a convenient location for configuring default settings via
   `UCSF_VPN_*` environment variables.
 
 * Add `ucsf vpn routing`, which shows the current IP routing table.
   It also reports on the default non-VPN network interface on the
   machine, and any tunnel devices.  By specifying `--full`, IP
   numbers are annotated with hostnames and `whois` information, if
   available.

 * Now `ucsf vpn` gives an error if it detects an unknown `--<flag>`
   or an unknown `--<key>=<value>` option.

 * Environment variable `UCSF_VPN_VERSION=x.y.z` is now passed to
   OpenConnect.

### Beta Features

 * Add argument `--flavor=<flavor>`, which defaults to
   `UCSF_VPN_FLAVOR`, which does not have a default value. If
   specified, folder `~/.config/ucsf-vpn/flavors/<flavor>/` must
   exist.

### Bug Fixes

 * `ucsf vpn start` ignored environment variable `NETRC`.


## Version 5.7.0 (2024-04-27)

### Bug Fixes

 * When `ucsf vpn start` fails, it would no longer detect when a wrong
   username of password was enter.

### Deprecated and Defunct

 * The use of `--method=pulse`, which uses the Pulse Secure GUI client
   to establish a VPN connection, is deprecated and will become
   defunct in a near-future release. Please use the default
   `--method=openconnect` instead.
 

## Version 5.6.1 (2023-05-09)

### New Features

 * Add support for controlling the ping timeout via environment
   variable `UCSF_VPN_PING_TIMEOUT`. This can be useful on very slow
   internet connections. Default is 1.0 seconds.


## Version 5.6.0 (2023-03-01)

### New Features

 * `ucsf vpn restart --force` restarts the VPN connection regardless
   of it is active or not.  This can be useful if the internet connection
   is completely broken.

### Bug Fixes

 * `ucsf vpn start` would display lots of OpenConnect output, at least
   with OpenConnect 8.20-1 on Ubuntu 22.04.  This output is now silenced.


## Version 5.5.1 (2022-09-28)

### Bug Fixes

 * `ucsf-vpn` gave an obscure error (e.g. `printf: %*R: invalid
   conversion specification`) if the password comprised of one or more
   `%` symbols.


## Version 5.5.0 (2022-06-14)

### New Features

 * `ucsf-vpn --version --full` now reports on both the `ucsf-vpn`
   version and the OpenConnect version.

 * `ucsf-vpn` now respected environment variable `NO_COLOR`. Set it to
   any non-empty value to disable colored output.

### Bug Fixes

 * `ucsf-vpn start` could give a false error saying connection to the
   VPN failed. Now it retries several times if the status is not what
   it expects.


## Version 5.4.0 (2022-01-30)

### Significant changes

 * Options `--user=<user>` and `--pwd=<pwd>` now take precedence over
   their corresponding entries in the ~/.netrc file.

 * Switch from using `openconnect` option `--juniper` to
   `--protocol=nc`.  The former is a legacy option that resolves to
   the latter, meaning this should be a backward compatible change.
   However, it might be that older versions of OpenConnect only
   recognizes `--juniper`.  If that is the case, then specify option
   `ucsf vpn --protocol=juniper start` to revert back to the old
   behavior.

### New Features

 * Added option `--protocol=<ptl>` for setting the VPN protocol, which
   can also be set via environment variable `UCSF_VPN_PROTOCOL`.  The
   default is `--protocol=nc` with the alternative protocol being
   `--protocol=pulse`, which _may_ be needed with newer versions of
   OpenConnect, such as 8.10.

 * Error messages now report on also the ping status of the VPN
   server, in case the VPN setup failed.

 * Error messages now provide a URL to the UCSF Web VPN for validating
   credentials when it is likely that the connection failed due to an
   incorrect username, password, or 2FA was given.

 * Now `ucsf vpn stop` tries to terminate OpenConnect a second time if
   the first attempt was not successful after 10 seconds.

### Defunct

 * Legacy, non-standard key-value pair CLI options without equal signs
   such as `--user alice` are now defunct. Use `--user=alice` instead.


## Version 5.3.0 (2020-08-10)

### New Features

 * When prompted for a token (e.g. `--token=prompt`) and pressing only
   ENTER (without entering anything), it will default to `push`.  This
   will make it easier to switch between the 2FA mobile application
   and the YubiKey.
 

## Version 5.2.0 (2020-06-13)

### New Features

 * An informative message prompts the users what additional action
   needs to be done whenever `--token=push` or `--token=phone` is
   used.

 * If the connection fails, the likely reason for the failure is now
   given as part of the error message, e.g. 'Incorrect username or
   password' or '2FA token not accepted'.

 * The verbose standard error messages from OpenConnect is only
   displayed if the connected fails, otherwise it is muffled.

 * Error messages now include the version of ucsf-vpn and OpenConnect.

 * Environment variable `UCSF_VPN_PING_SERVER` now supports specifying
   multiple servers (separated by space).
   
 * The default ping server is now 9.9.9.9 (Quad9.net).
 

## Version 5.1.0 (2020-03-24)

### New Features

 * The server used for testing the internet connection by pinging it,
   can now be controlled by environment variable
   `UCSF_VPN_PING_SERVER`.
 
 * The prompt asking for type of token now echoes type of token
   requested.

 * If OpenConnect requires additional options, then these can be
   specified also via environment variable `UCSF_VPN_EXTRAS`.

 * The validation toward the third-party https://ipinfo.io/ service
   done by `ucsf-vpn status`, `ucsf-vpn start` and `ucsf-vpn stop` can
   be disabled by specifying option `--validate=pid`, or by setting
   environment variable `UCSF_VPN_VALIDATE=pid`.

 * Sudo rights are now established upfront with an informative
   message.

### Bug Fixes

 * It was not possible to pass additional options of kind `--key
   value` to the `openconnect` client; they were dropped with an
   incorrect warning on using `--key=value` instead.
 

## Version 5.0.0 (2020-03-20)

### Significant changes

 * `ucsf-vpn start` and `ucsf-vpn stop` is significantly faster
   because in previous versions there was a bug (see below) causing it
   to query for public IP information multiple times, which was slow.

 * Now supporting proper key-value pair CLI options,
   e.g. `--user=alice`.
 
### New Features

 * `ucsf-vpn stop` makes sure to terminate the process that `ucsf-vpn
   start` started, which works by having OpenConnect record the
   process ID to file.  Previously, `ucsf-vpn stop` terminated _all_
   `openconnect` process found.

 * Messages are now outputted in different colors if the terminal
   supports it.  Success message are outputted in green, warnings in
   yellow, errors in red, and debug messages in gray.  Message from
   OpenConnect are outputted using the default foreground color, which
   is typically white.  Similarly, prompts are highlighted in bright
   yellow.  Disable with `--theme=none` or set environment variable
   `UCSF_VPN_THEME=none`.

 * Now `ucsf-vpn` displays parts of the help and `ucsf-vpn --help` the
   full.

### Bug Fixes

 * `ucsf-vpn` failed to cache collected public IP information
   resulting in it queried the same public IP information multiple
   times.

### Deprecated

 * Legacy, non-standard key-value pair CLI options without equal signs
   such as `--user alice` are now deprecated. Use `--user=alice`
   instead.

 * CLI option `--skip` has been dropped.  It is now the default
   behavior.
 

## Version 4.3.0 (2020-03-16)

### New Features

 * The VPN server can now be set via environment variable
   `UCSF_VPN_SERVER` as an alternative to specifying option
   `--server`. `ucsf-vpn start` will output 'Connection to server
   <server> ...' to indicate which server is used.

 * If a custom VPN server is used, then the ~/.netrc file is search
   for that first with a fallback to `remote.ucsf.edu`.  This avoids
   having to update the .netrc file when using an alternative UCSF-VPN
   server.

 

## Version 4.2.0 (2019-10-15)

### New Features

 * Updated how the information on the current connection is reported
   by for instance `ucsf-vpn status`.

### Bug Fixes

 * The reported IP could be garbled with a newline and 'https'.
 

## Version 4.1.0 (2019-05-15)

### New Features

 * Attempts to connect using `--token sms` will now give an
   informative error message explaining that is not supported by the
   OpenConnect interface.

### Bug Fixes

 * `ucsf-vpn --token <digits>` only supported six-digit tokens; now
   seven-digit tokens are also supported.
   

## Version 4.0.0 (2018-07-31)

### Significant Changes

 * The default VPN method is now OpenConnect (`--method openconnect`).
   The previous method, Pulse Secure Client, is available by using
   `--method pulse`.

 * The default is now `--token push` (was `--token prompt`).
   
### New Features

 * Added support to connect to the UCSF VPN using OpenConnect (>=
   7.08), which is available on recent Linux distributions such as
   Ubuntu 18.04.  The advantage of using OpenConnect rather that the
   Pulse Secure Client, is in addition of not requiring a proprietary
   software, it is also more stable because it does not operate by
   emulating key and mouse clicks in a GUI.  The disadvantage is that
   it requires sudo, i.e. you need to have admin rights.

 * Added option `--method` to control whether to use OpenConnect
   (`openconnect`) or the Pulse Secure Client (`pulse`).  The default,
   which is `openconnect`, can be controlled via environment variable
   `UCSF_VPN_METHOD`.

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
   UCSF has now removed the notification about the new 2FA
   requirements.


## Version 3.2.0 (2017-12-14)

### New Features

 * Now `ucsf-vpn start --gui` looks in the Pulse Secure GUI config
   file to identify which of several connections is for the target VPN
   URL.  If none matches, a proper connection is automatically added
   to the settings.
   
 * Add option `--url <url>` for specifying the VPN URL.  Currently,
   only used for validation.

 * Now `--realm <realm>` is acknowledged also for `--gui` (though UCSF
   VPN still only 'Dual Factor Pulse Clients').

 * Now `ucsf-vpn troubleshoot` reports on the configured connections
   available in the Pulse Secure GUI.  If a connection to the
   UCSF-specific VPN URL is missing, then a warning is displayed.

 * The default value for `--token` can be set via env var
   `UCSF_VPN_TOKEN`.


## Version 3.1.1 (2017-12-12)
 
### Software Quality

 * Fixed Bash code according to ShellCheck suggestions.

 * Running ShellCheck code analysis via Travis CI.
 

## Version 3.1.0 (2017-12-09)

### New Features

 * Added support for `--token push` and `--token phone`, which will
   authenticate via the Duo app (approve and confirm), and phone call
   ("press any key"), respectively.  Also, accepts `--token phone2`,
   and `--token sms` but not sure the UCSF supports those.

 * Now `ucsf-vpn start --gui` minimizes the main Pulse Secure GUI
   window as soon as it is no longer needed.

 * Now `ucsf-vpn start --gui` waits for the popup windows to close
   before verifying that the VPN connection is working.

### Bug Fixes

 * `ucsf-vpn start --gui` would not works if Pulse Secure GUI was
   already open but minimized.

 * `ucsf-vpn stop` failed to close the Pulse Secure GUI window.


## Version 3.0.0 (2017-12-09)

### Significant Changes

 * Two-factor authentication (2FA) is now supported by sending user
   credentials and 2FA tokens via the Pulse Secure GUI by utilizing
   xdotool (automated mouse clicks and key presses over X11).  It's
   not perfect, but it works.
 
 * Now `ucsf-vpn start --gui` is the default.

 * `ucsf-vpn start-gui` was renamed to `ucsf-vpn open-gui`.

### New Features

 * Now `ucsf-vpn start` (with default `--gui`) connects to the UCSF
   VPN via the Pulse Secure GUI (by sending mouse and key sequences).

 * Added `--gui` (default) and `--no-gui` to control whether `ucsf-vpn
   start` should the Pulse Secure GUI or the CLI.

 * Added `--token <token>` to specify the one-time two-factor
   authentication (2FA) token, where `--token true` (default) will
   prompt user to enter token, and `--token false` will try to connect
   without 2FA.

 * Added `--notification` (default) and `--no-notification` to
   indicate whether the UCSF VPN login includes a "Pre Sign-In
   Notification" message that needs to be confirmed or not.
  
 * Added `--speed <factor>` for adjusting the waiting times between
   submitting information to the GUI.

 * Now `ucsf-vpn troubleshoot` also reports on `pulsesvc --version`.

 * Use environment variable `PULSEPATH` to override the default
   location (/usr/local/pulse/) of the Pulse Secure software and
   libraries.

### Deprecated & Defunct

 * Credentials in ~/.ucsfvpnrc are defunct. Use ~/.netrc instead.

 
## Version 2.3.0 (2017-12-08)

### New Features

 * Added `ucsf-vpn log`, which output the log file.
 
 * Added `ucsf-vpn troubleshoot`, which reports on errors in the log
   file.

### Bug Fixes

 * Authentication credentials in ~/.netrc were not found on systems
   where where awk does not support POSIX regular expressions.
   

## Version 2.2.0 (2017-11-10)

### New Features

 * If username and/or password are not specified or not identifiable
   from the ~/.netrc file, then the user will be prompted to enter
   them.
 

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

 * Now `ucsf-vpn` checks for working internet connection and adjust
   accordingly.  For instance, `ucsf-vpn restart` will not try to
   infer public IP number if there is no internet connection but
   instead it will just go ahead an restart the local VPN service.
   
 * Add `ucsf-vpn restart`.


## Version 1.0.0 (2016-09-02)

 * First public release.
