[![shellcheck](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/shellcheck.yml)
[![codespell](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/codespell.yml/badge.svg)](https://github.com/HenrikBengtsson/ucsf-vpn/actions/workflows/codespell.yml)

For recent updates, see [NEWS].

_WARNING: `ucsf-vpn` no longer works, because UCSF migrated to use the
GlobalProtect VPN protocol. The Pulse/Ivanti VPN protocol, which
`ucsf-vpn` used, was decommissioned on 2025-04-16.

The plan is to re-implement `ucsf-vpn` for GlobalProtect VPN, which is
major work. Please see
<https://github.com/HenrikBengtsson/ucsf-vpn/issues/69/> for updates._



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
Enter 'push' (default), 'phone', 'sms', a 6 or 7 digit Duo token, or press your YubiKey: <six-digit token>
OK: OpenConnect status: 'openconnect' process running (started 00h00m01s ago on 2024-06-25T09:05:20-07:00; PID=14549)
OK: IP routing tunnels: [n=1] tun0
OK: Public IP information (UCSF IT): public_ip=10.49.88.54, network='UCSF Network - Private Space'
OK: Flavor: default
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
OK: IP routing tunnels: none
OK: Public IP information (UCSF IT): public_ip=123.145.254.42, network='not UCSF'
OK: Not connected to the VPN
```


## Check status on VPN connection

To check whether you are connected to the UCSF VPN or not, call:

```sh
$ ucsf-vpn status
OpenConnect status: 'openconnect' process running (started 08h31m27s ago on 2024-06-25T16:20:00-07:00; PID=17419)
IP routing tunnels: [n=1] tun0
OK: Public IP information (UCSF IT): public_ip=10.49.88.54, network='UCSF Network - Private Space'
Flavor: default
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
 --token=<token>  One-time two-factor authentication (2FA) token or method:
                   - 'prompt' (user is prompted to enter the token),
                   - 'push' ("approve and confirm" in Duo app; default),
                   - 'phone' (receive phone call and "press any key"),
                   - 'sms' (receive code via text message),
                   -  6 or 7 digit token (from Duo app), or
                   -  44-letter YubiKey token ("press YubiKey")
 --user=<user>    UCSF Active Directory ID (username)
 --pwd=<pwd>      UCSF Active Directory ID password
 --presudo=<lgl>  Established sudo upfront (true; default) or not (false)

 --server=<host>  VPN server (default is 'remote.ucsf.edu')
 --realm=<realm>  VPN realm (default is 'Dual-Factor Pulse Clients')
 --url=<url>      VPN URL (default is https://{{server}}/pulse)
 --protocol=<ptl> VPN protocol, e.g. 'nc' (default) and 'pulse'
 --validate=<how> One or more of 'ipinfo', 'iproute', 'pid', 'ucsfit',
                  e.g. 'pid,iproute,ucsfit' (default)
 --theme=<theme>  Either 'cli' (default) or 'none'
 --flavor=<flvr>  Use a customized flavor of the VPN (default: 'none')

Flags:
 --verbose        More verbose output
 --help           Display full help
 --version        Display version
 --full           Display more information
 --force          Force command
 --args           Pass any remaining options to 'openconnect'

Examples:
 ucsf-vpn --version --full
 ucsf-vpn start --user=alice --token=push
 ucsf-vpn stop
 UCSF_VPN_TOKEN=prompt ucsf-vpn start --user=alice --pwd=secrets
 ucsf-vpn start
 ucsf-vpn routings --full


Environment variables:
 UCSF_VPN_PROTOCOL     Default value for --protocol
 UCSF_VPN_SERVER       Default value for --server
 UCSF_VPN_TOKEN        Default value for --token
 UCSF_VPN_THEME        Default value for --theme
 UCSF_VPN_VALIDATE     Default value for --validate
 UCSF_VPN_PING_SERVER  Ping server to validate internet (default: 9.9.9.9)
 UCSF_VPN_PING_TIMEOUT Ping timeout (default: 1.0 seconds)
 UCSF_VPN_EXTRAS       Additional arguments passed to OpenConnect

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
* OpenConnect (>= 7.08) (installed: 9.12-1build5)
* sudo

VPN Protocol:
Different versions of OpenConnect support different VPN protocols.
Using '--protocol=nc' (default) has been confirmed to work when using
OpenConnect 7.08, and '--protocol=pulse' for OpenConnect 8.10.
The 'nc' protocol specifies the old "Juniper Network Connect" protocol,
and 'pulse' the newer "Pulse Secure" protocol.  For older version of
OpenConnect that recognizes neither, specify '--protocol=juniper',
which will results in using 'openconnect' legacy option '--juniper'.

Troubleshooting:
* Verify your username and password at https://remote.ucsf.edu/.
  This should be your UCSF Active Directory ID (username); neither
  MyAccess SFID (e.g. 'sf*****') nor UCSF email address will work.

Useful resources:
* UCSF VPN - Remote connection:
  - https://it.ucsf.edu/service/vpn-remote-connection
* UCSF Web-based VPN Interface:
  - https://remote-vpn01.ucsf.edu/ (preferred)
  - https://remote.ucsf.edu/
* UCSF Two-Factory Authentication (2FA):
  - https://it.ucsf.edu/services/duo-two-factor-authentication
* UCSF Managing Your Passwords:
  - https://it.ucsf.edu/services/managing-your-passwords

Version: 6.3.0
Copyright: Henrik Bengtsson (2016-2025)
License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
Source: https://github.com/HenrikBengtsson/ucsf-vpn
```



## Required software

The `uscf-vpn` tool requires:

1. OpenConnect (>= 7.08)
2. Curl
3. Bash
4. Admin rights (sudo)


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
-r-xr-xr-x 1 alice alice 58480 Nov 13 11:07 bin/ucsf-vpn
Version built: 6.3.0
Building bin/ucsf-vpn from src/ucsf-vpn.sh ... done
```

[NEWS]: NEWS.md
[UCSF VPN web proxy]: https://remote-vpn01.ucsf.edu/