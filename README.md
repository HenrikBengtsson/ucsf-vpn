[![shellcheck](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/shellcheck.yml)
[![codespell](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/codespell.yml/badge.svg)](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/codespell.yml)

For recent updates, see [NEWS].


# A UCSF VPN Client for Linux

The `ucsf-vpn` CLI command is a Linux-only tool for connecting to and disconnecting from the UCSF VPN server.  It is based on the official UCSF instructions provided by the [UCSF IT](https://it.ucsf.edu/services/vpn) with additional instructions obtained through private communication.

![](screencast.gif)


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
NOTE: Open the Duo Mobile app on your smartphone or tablet to confirm ...
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
  "ip": "10.49.88.54",
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

 --validate=<how> One or more of 'ipinfo', 'iproute', 'pid', 'ucsfit',
                  e.g. 'pid,iproute,ucsfit' (default)
 --theme=<theme>  Either 'cli' (default) or 'none'

Flags:
 --verbose        More verbose output
 --help           Display full help
 --version        Display version
 --full           Display more information
 --force          Force command
 --args           Pass any remaining options to 'gpclient'

Examples:
 ucsf-vpn --version --full
 ucsf-vpn start --user=alice
 ucsf-vpn start --user=alice --pwd=secrets
 ucsf-vpn start
 ucsf-vpn stop


Environment variables:
 UCSF_VPN_VALIDATE     Default value for --validate
 UCSF_VPN_PING_SERVER  Ping server to validate internet (default: 9.9.9.9)
 UCSF_VPN_PING_TIMEOUT Ping timeout (default: 1.0 seconds)
 UCSF_VPN_THEME        Default value for --theme
 UCSF_VPN_EXTRAS       Additional arguments passed to GlobalProtect

User credentials:
If user credentials (--user and --pwd) are neither specified nor given
in ~/.netrc, then you will be prompted to enter them. To specify them
in ~/.netrc file, use the following format:

  machine gp-ucsf.ucsf.edu
      login alice.bobson@ucsf.edu
      password secrets

For security, the ~/.netrc file should be readable only by
the user / owner of the file. If not, then 'ucsf-vpn start' will
set its permission accordingly (by calling chmod go-rwx ~/.netrc).

Requirements:
* GlobalProtect gpclient (installed: 2.4.5)
* xdotool (installed: 3.20160805.1)
* sudo

Troubleshooting:
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

Version: 6.9.9-9000
Copyright: Henrik Bengtsson (2016-2025)
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

The `ucsf-vpn details` queries the https://ipinfo.io/ service for
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
-r-xr-xr-x 1 alice alice 43425 Nov 13 13:50 bin/ucsf-vpn
Version built: 6.9.9-9000
Building bin/ucsf-vpn from src/ucsf-vpn.sh ... done
```

[NEWS]: NEWS.md
[UCSF VPN web proxy]: https://remote.ucsf.edu/
[gpclient]: https://github.com/yuezk/GlobalProtect-openconnect
[xdotools]: https://github.com/jordansissel/xdotool