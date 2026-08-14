[![shellcheck](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/shellcheck.yml)
[![codespell](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/codespell.yml/badge.svg)](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/codespell.yml)

For recent updates, see [NEWS].


# A UCSF VPN Client for Linux

The `ucsf-vpn` CLI command is a Linux-only tool for connecting to and disconnecting from the UCSF VPN server.  It is based on the official UCSF instructions provided by the [UCSF IT](https://it.ucsf.edu/service/vpn-remote-connection) with additional instructions obtained through private communication.


## Connect to the VPN

To connect to the UCSF VPN, call:

```sh
$ ucsf-vpn start --user=alice
WARNING: This action ('ucsf-vpn start') requires administrative ("sudo") rights.
Enter the password for your account ('alice84') on your local computer ('alice-laptop'):
Enter your UCSF Active Directory password: <password>
GlobalProtect status: 'gpclient' process running (started 00h00m05s ago on 2025-11-13T13:37:58-08:00; PID=1929509)
IP routing tunnels: yes (n=1 tun0)
Public IP information (UCSF IT): public_ip=10.51.19.45, network='UCSF Network - Private Space'
Connected to the VPN
```

If you have problems connecting to the VPN using `ucsf-vpn`, make sure you use the correct username and password by logging in via the [UCSF VPN web proxy].

Alternatively to command-line options, the username and password can also be specified in file `~/.netrc` (or the file that environment variable `NETRC` specifies).  See `ucsf-vpn --help` for more details.  With a properly setup `~/.netrc` entry, you can connect to the UCSF VPN using:

```sh
$ ucsf-vpn start
NOTE: Open the Duo Mobile app on your smartphone to confirm, unless recently authenticated ...
```


## Disconnect from the VPN

To disconnect from the UCSF VPN, call:

```sh
$ ucsf-vpn stop
OK: GlobalProtect status: No 'gpclient' process running
OK: IP routing tunnels: none
OK: Public IP information (UCSF IT): public_ip=123.145.254.42, network='not UCSF'
OK: Not connected to the VPN
```


## Check status on VPN connection

To check whether you are connected to the UCSF VPN or not, call:

```sh
$ ucsf-vpn status
GlobalProtect status: 'gpclient' process running (started 00h31m54s ago on 2025-11-13T13:37:58-08:00; PID=1929509)
IP routing tunnels: yes (n=1 tun0)
Public IP information (UCSF IT): public_ip=10.51.19.45, network='UCSF Network - Private Space'
Connected to the VPN
```

To get full details of your current internet connection in JSON format, call:

```sh
$ ucsf-vpn details
{
  "status":"success",
  "country":"United States",
  "countryCode":"US",
  "region":"CA",
  "regionName":"California",
  "city":"San Francisco",
  "zip":"94122",
  "lat":37.7562,"lon":-122.4866,"timezone":"America/Los_Angeles",
  "isp":"University of California - Office of the President",
  "org":"University of California San Francisco",
  "as":"AS5653 University of California San Francisco",
  "query":"169.230.248.43"
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
 reconnect        Reconnect to VPN
 restart          Disconnect and reconnect to VPN
 toggle           Connect to or disconnect from VPN
 status           Display VPN connection status
 details          Display connection details in JSON format
 routing          Display IP routing details
 log              Display log file

Options:
 --user=<user>    UCSF Active Directory ID (username)
 --pwd=<pwd>      UCSF Active Directory ID password

 --server=<host>  VPN server (gateway) to connect to, specified as a
                  hostname (default: gp-ucsf.ucsf.edu)

 --validate=<how> One or more of 'ipinfo', 'iproute', 'pid', 'ucsfit',
                  e.g. 'pid,iproute,ucsfit' (default)
 --theme=<theme>  Either 'cli' (default) or 'none'
 --browser[=<browser>]
                  Sign in to the VPN in an external web browser, instead of
                  in the built-in pop-up window, e.g. 'firefox', 'chrome',
                  'default', or the path to a web browser. Without a value,
                  the default web browser of your desktop environment is
                  used. Use this to have the web browser, and not
                  'ucsf-vpn', fill in the single sign-on form. At the end of
                  the sign-in, the web browser asks to open the 'GP Connect'
                  application, which has to be confirmed, because that is
                  how the sign-in reaches the VPN client. Note, a web
                  browser installed as a Snap, e.g. Ubuntu's
                  /usr/bin/firefox, cannot open that application, and will
                  therefore never complete the sign-in

Flags:
 --verbose        More verbose output
 --help           Display full help
 --version        Display version
 --full           Display more information
 --force          Force command
 --args           Pass any remaining options to 'gpclient', or to
                  'gpclient connect', depending on which of the two
                  accepts the option

Examples:
 ucsf-vpn --version --full
 ucsf-vpn start --user=alice
 ucsf-vpn start --user=alice --pwd=secrets
 ucsf-vpn start
 ucsf-vpn start --browser=chrome
 ucsf-vpn stop


Environment variables:
 UCSF_VPN_SERVER       Default value for --server
 UCSF_VPN_VALIDATE     Default value for --validate
 UCSF_VPN_PING_SERVER  Ping server to validate internet (default: 9.9.9.9).
                       Multiple servers may be specified separated by
                       space or comma, in which case the first one that
                       replies is used
 UCSF_VPN_PING_TIMEOUT Ping timeout (default: 1.0 seconds)
 UCSF_VPN_THEME        Default value for --theme
 UCSF_VPN_BROWSER      Default value for --browser
 UCSF_VPN_AUTH_TIMEOUT Seconds to wait for the login to complete, e.g.
                       entering credentials and confirming with Duo
                       (default: 300 seconds)
 UCSF_VPN_EXTRAS       Additional arguments passed to GlobalProtect
 UCSF_VPN_UCSFIT_ATTEMPTS
                       Number of times --validate=ucsfit queries the UCSF IT
                       network service before giving up (default: 5)
 UCSF_VPN_UCSFIT_DELAY Seconds to wait between those attempts (default: 3)

User credentials:
If user credentials (--user and --pwd) are not specified, 'ucsf-vpn' looks
for VPN credentical in your NETRC file as given by environment variable
'NETRC'. If not set, then it looks for file ~/.config/ucsf-vpn/netrc, and
if that does not exist, ~/.netrc. To specify your credentials in the NETRC
file, use the following format:

  machine gp-ucsf.ucsf.edu
      login alice.bobson@ucsf.edu
      password secrets

For security, the NETRC should be readable only by the owner of that file.
If not, then 'ucsf-vpn start' will set its permission accordingly (by
calling chmod go-rwx ~/.netrc). If the credentials are not still not
found, you will be prompted to enter them.

Requirements:
* GlobalProtect gpclient (installed: 2.6.5)
* xdotool (installed: 3.20160805.1); only used for automating the
  login pop-up window on X11. On Wayland, the credentials have to be
  entered manually in that window
* curl (installed: 8.5.0)
* sudo

Troubleshooting:
* `ucsf vpn start` uses `ping` to assert there is a working internet
  connection. If ping is disabled on your network, try with:
  `UCSF_VPN_PING_SERVER=127.0.0.1 ucsf vpn start`

* With `--browser`, the web browser asks for permission to open the
  'globalprotectcallback' link with the 'GP Connect' application, e.g.
  "Open GP Connect?" in Chrome. That permission has to be granted,
  because it is how the sign-in reaches the VPN client. If the prompt is
  dismissed, the web page says "Authentication Complete", but
  `ucsf-vpn start` waits until it times out. The permission is remembered
  per website, if you accept it permanently. Note, a web browser installed
  as a Snap, e.g. Ubuntu's /usr/bin/firefox, is never allowed to open that
  application. The symptom of that is a web page saying "Authentication
  Failed"

* Verify your UCSF credentials at https://remote.ucsf.edu/.
  Use your UCSF email address for 'Username'.

Useful resources:
* UCSF VPN - Remote connection:
  - https://it.ucsf.edu/service/vpn-remote-connection
* UCSF Web-based VPN Interface:
  - https://remote.ucsf.edu/
* UCSF Two-Factory Authentication (2FA):
  - https://it.ucsf.edu/service/multi-factor-authentication-duo
* UCSF Managing Your Passwords:
  - https://it.ucsf.edu/services/managing-your-passwords

Version: 7.1.0-9000
Copyright: Henrik Bengtsson (2016-2026)
License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
Source: https://github.com/HenrikBengtsson/ucsf-vpn
```



## Required software

The `uscf-vpn` tool requires:

1. [gpclient] - GlobalProtect VPN client for Linux
1. [xdotools] - command-line X11 Automation Tool
2. curl
3. bash
4. admin rights (sudo)


## Privacy

The `ucsf-vpn` software pings 9.9.9.9 (<https://www.quad9.net/>; a nonprofit
organization) to check whether there is a working internet connection or not.
Environment variable `UCSF_VPN_PING_SERVER` can be use to specify a different
ping server, e.g. `UCSF_VPN_PING_SERVER=www.ucsf.edu`.

The `ucsf-vpn details` queries the <https://ip-api.com/> service for
information on the current internet connection.

The `ucsf-vpn` software _neither_ collects nor stores your local or UCSF
credentials.


## Building from source

The self-contained `bin/ucsf-vpn` script is generated from
`src/ucsf-vpn.sh` and `src/incl/*.sh`. To rebuild `bin/ucsf-vpn`,
use:

```sh
$ make build
./build.sh
Building bin/ucsf-vpn from src/ucsf-vpn.sh ...
-r-xr-xr-x 1 alice alice 61688 Aug 15 00:24 bin/ucsf-vpn
Version built: 7.1.0-9000
Building bin/ucsf-vpn from src/ucsf-vpn.sh ... done
```

[NEWS]: NEWS.md
[UCSF VPN web proxy]: https://remote.ucsf.edu/
[gpclient]: https://github.com/yuezk/GlobalProtect-openconnect
[xdotools]: https://github.com/jordansissel/xdotool