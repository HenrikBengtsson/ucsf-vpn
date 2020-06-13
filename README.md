[![Build Status](https://travis-ci.org/HenrikBengtsson/ucsf-vpn.svg?branch=develop)](https://travis-ci.org/HenrikBengtsson/ucsf-vpn)

For recent updates, see [NEWS].


# A UCSF VPN Client for Linux

The `ucsf-vpn` CLI command is a Linux-only tool for connecting to and disconnecting from the UCSF VPN server.  It is based on the official UCSF instructions provided by the [UCSF IT](https://it.ucsf.edu/services/vpn) with additional instructions obtained through private communication.

![](screencast.gif)


## Connect to the VPN

To connect to the UCSF VPN, call:

```sh
$ ucsf-vpn start --user=alice --token=prompt
WARNING: This action ('ucsf-vpn start') requires administrative ("sudo") rights.
Enter the password for your account ('alice84') on your local computer ('alice-laptop'):
Enter your UCSF Active Directory password: <password>
Enter 'push', 'phone', 'sms', a 6 or 7 digit Duo token, or press your YubiKey: <six-digit token>
OK: OpenConnect status: 'openconnect' process running (PID=14549)
OK: Public IP information: ip=128.218.43.42, hostname=, org=AS5653 University of California San Francisco
OK: Connected to the VPN
```

If you have problems connecting to the VPN using `ucsf-vpn`, make sure you use the correct username and password by logging in via the [UCSF VPN web proxy].

Alternatively to command-line options, the username and password can also be specified in file `~/.netrc` (or the file that environment variable `NETRC` specifies).  See `ucsf-vpn --help` for more details.  With a properly setup `~/.netrc` entry, you can connect to the UCSF VPN using:

```sh
$ ucsf-vpn start
NOTE: Open the Duo Mobile app on your smartphone or tablet to confirm ...
```
after approving the push notification on your Duo Mobile app (the default is `--token=push`).


## Disconnect from the VPN

To disconnect from the UCSF VPN, call:

```sh
$ ucsf-vpn stop
OK: OpenConnect status: No 'openconnect' process running
OK: Public IP information: ip=123.145.254.42, hostname=123.145.254.42.fiber.dynamic.sonic.net, org=AS46375 Sonic Telecom LLC
OK: Not connected to the VPN
```


## Check status on VPN connection

To check whether you are connected to the UCSF VPN or not, call:

```sh
$ ucsf-vpn status
OpenConnect status: 'openconnect' process running (PID=17419)
Public IP information: ip=128.218.43.42, hostname=, org=AS5653 University of California San Francisco
Connected to the VPN
```

To get full details of your current internet connection in JSON format, call:

```sh
$ ucsf-vpn details
{
  "ip": "128.218.43.42",
  "city": "San Francisco",
  "region": "California",
  "country": "US",
  "loc": "37.7749,-122.4194",
  "org": "AS5653 University of California San Francisco",
  "postal": "94103",
  "timezone": "America/Los_Angeles",
  "readme": "https://ipinfo.io/missingauth"
}
```


## Installation

The `ucsf-vpn` script is distributed under GPL (>= 2.1) and the source
code is available at https://github.com/HenrikBengtsson/ucsf-vpn/.  To
"install" it, just do

```
$ curl -O https://raw.githubusercontent.com/HenrikBengtsson/ucsf-vpn/master/bin/ucsf-vpn
$ chmod ugo+x ucsf-vpn
```



## Full command-line help
```
Connect to and Disconnect from the UCSF VPN

Usage:
 ucsf-vpn <command> [flags] [options]

Commands:
 start            Connect to VPN
 stop             Disconnect from VPN
 restart          Disconnect and reconnect to VPN
 toggle           Connect to or disconnect from VPN
 status           Display VPN connection status
 details          Display connection details in JSON format
 log              Display log file
 troubleshoot     Scan log file for errors (only for '--method=pulse')

Options:
 --token=<token>  One-time two-factor authentication (2FA) token or method:
                   - 'prompt' (user is prompted to enter the token),
                   - 'push' ("approve and confirm" in Duo app; default),
                   - 'phone' (receive phone call and "press any key"),
                   - 'sms' (receive code via text message),
                   -  6 or 7 digit token (from Duo app), or
                   -  44-letter YubiKey token ("press YubiKey")
 --user=<user>    UCSF Active Directory ID (username)
 --pwd=<pwd>      UCSF Active Directory ID password

 --server=<host>  VPN server (default is 'remote.ucsf.edu')
 --realm=<realm>  VPN realm (default is 'Dual-Factor Pulse Clients')
 --url=<url>      VPN URL (default is https://{{server}}/pulse)
 --method=<mth>   Either 'openconnect' (default) or 'pulse'
 --validate=<how> Either 'ipinfo', 'pid', or 'pid,ipinfo'
 --theme=<theme>  Either 'cli' (default) or 'none'

Flags:
 --verbose        More verbose output
 --help           Display full help
 --version        Display version
 --force          Force command

Examples:
 ucsf-vpn start --user=alice --token=push
 ucsf-vpn stop
 UCSF_VPN_TOKEN=prompt ucsf-vpn start --user=alice --pwd=secrets
 ucsf-vpn start


Environment variables:
 UCSF_VPN_METHOD       Default value for --method
 UCSF_VPN_SERVER       Default value for --server
 UCSF_VPN_TOKEN        Default value for --token
 UCSF_VPN_THEME        Default value for --theme
 UCSF_VPN_VALIDATE     Default value for --validate
 UCSF_VPN_PING_SERVER  Ping server to validate internet (default: 9.9.9.9)
 UCSF_VPN_EXTRAS       Additional arguments passed to OpenConnect

Commands and Options for Pulse Security Client only (--method=pulse):
 open-gui         Open the Pulse Secure GUI
 close-gui        Close the Pulse Secure GUI (and any VPN connections)

 --gui            Connect to VPN via Pulse Secure GUI
 --no-gui         Connect to VPN via Pulse Secure CLI (default)
 --speed=<factor> Control speed of --gui interactions (default is 1.0)

Any other options are passed to Pulse Secure CLI as is (only --no-gui).

User credentials:
If user credentials (--user and --pwd) are neither specified nor given
in ~/.netrc, then you will be prompted to enter them. To specify them
in ~/.netrc file, use the following format:

  machine remote.ucsf.edu
      login alice
      password secrets

For security, the ~/.netrc file should be readable only by
the user / owner of the file. If not, then 'ucsf-vpn start' will
set its permission accordingly (by calling chmod go-rwx ~/.netrc).

Requirements:
* Requirements when using OpenConnect (CLI):
  - OpenConnect (>= 7.08) (installed: 7.08-3ubuntu0.18.04.1)
  - sudo
* Requirements when using Junos Pulse Secure Client (GUI):
  - Junos Pulse Secure client (>= 5.3) (installed: 5.3-3-Build553)
  - Ports 4242 (UDP) and 443 (TCP)
  - `curl`
  - `xdotool` (when using 'ucsf-vpn start --method=pulse --gui')
  - No need for sudo rights

Pulse Secure GUI configuration:
Calling 'ucsf-vpn start --method=pulse --gui' will, if missing,
automatically add a valid VPN connection to the Pulse Secure GUI
with the following details:
 - Name: UCSF
 - URL: https://remote.ucsf.edu/pulse
You may change the name to you own liking.

Troubleshooting:
* Verify your username and password at https://remote.ucsf.edu/.
  This should be your UCSF Active Directory ID (username); neither
  MyAccess SFID (e.g. 'sf*****') nor UCSF email address will work.
* If you are using the Pulse Secure client (`ucsf-vpn --method=pulse`),
  - Make sure ports 4242 & 443 are not used by other processes
  - Make sure 'https://remote.ucsf.edu/pulse' is used as the URL
  - Run 'ucsf-vpn troubleshoot' to inspect the Pulse Secure logs

Useful resources:
* UCSF VPN information:
  - https://software.ucsf.edu/content/vpn-virtual-private-network
* UCSF Web-based VPN Interface:
  - https://remote-vpn01.ucsf.edu/ (preferred)
  - https://remote.ucsf.edu/
* UCSF Two-Factory Authentication (2FA):
  - https://it.ucsf.edu/services/duo-two-factor-authentication
* UCSF Managing Your Passwords:
  - https://it.ucsf.edu/services/managing-your-passwords

Version: 5.2.0-9000
Copyright: Henrik Bengtsson (2016-2020)
License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
Source: https://github.com/HenrikBengtsson/ucsf-vpn
```



## Required software

### OpenConnect (default)

The `uscf-vpn` tool requires:

1. OpenConnect (>= 7.08)
2. Curl
3. Bash
4. Admin rights (sudo). If not, use the below Pulse Secure Client approach instead

OpenConnect (>= 7.08) is available on for instance Ubuntu 18.04 LTS (Bionic Beaver), but not on older LTS version.  For instance, Ubuntu 16.04 (Xenial Xerus) only provides OpenConnect 7.06, which [fails to connect with an error](https://github.com/HenrikBengtsson/ucsf-vpn/issues/4).  [There is a confirmed way to force install this](https://github.com/HenrikBengtsson/ucsf-vpn/issues/4) on to Ubuntu 16.04 from the Ubuntu 17.04 (Zesty) distribution, but it is not clear whether such an installation leaves the system in a stable state or not.  Moreover, due to library dependencies, it appears not possible to have OpenConnect 7.08 and Pulse Secure 5.3-3 installed at the same time.


### Pulse Secure Client (legacy)

If you don't have OpenConnect (>= 7.08) you can use `ucsf-vpn --method=pulse` (or set environment variable `UCSF_VPN_METHOD=pulse`) to connect to the UCSF VPN using the Junos Pulse Secure client (Pulse Secure, LLC).  That software, which is a **closed-source proprietary software** (*), can be downloaded from UCSF website:

* https://software.ucsf.edu/content/vpn-virtual-private-network

Access to that page requires UCSF MyAccess Login (but no UCSF VPN).

Note: `ucsf-vpn --method=pulse` is just a convenient wrapper script around the Pulse Secure client.  It is assumed that `pulsesvc` is available under `/usr/local/pulse/`. If not, set `PULSEPATH` to the folder where it is installed.


## Privacy

The `ucsf-vpn` software pings 9.9.9.9 (<https://www.quad9.net/>; a nonprofit
organization) to check whether there is a working internet connection or not.
Environment variable `UCSF_VPN_PING_SERVER` can be use to specify a different
ping server, e.g. `UCSF_VPN_PING_SERVER=www.ucsf.edu`.

The `ucsf-vpn` software also queries the https://ipinfo.io/ service to infer
whether a VPN connection is established or not, and to provide public IP
information on your current internet connection.  To disable this check, use
`--validate=pid`, or environment variable `UCSF_VPN_VALIDATE=pid`, which
uses the PID file of OpenConnect to decide whether a VPN connection is
established or not.  This only works for `--method=openconnect`.

The `ucsf-vpn` software _neither_ collects nor stores your local or UCSF
credentials.


[NEWS]: NEWS.md
[UCSF VPN web proxy]: https://remote-vpn01.ucsf.edu/