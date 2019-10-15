[![Build Status](https://travis-ci.org/HenrikBengtsson/ucsf-vpn.svg?branch=develop)](https://travis-ci.org/HenrikBengtsson/ucsf-vpn)

For recent updates, see [NEWS](NEWS.md).


# UCSF VPN client (Linux)

The `ucsf-vpn` CLI command is a Linux-only tool for connecting to and disconnecting from the UCSF VPN server.  It is based on the official UCSF instructions provided by the [UCSF IT](https://it.ucsf.edu/services/vpn) with additional instructions obtained through private communication.

## Connect
```sh
$ ucsf-vpn start --user alice --pwd secrets --token prompt
Enter 'push', 'phone', 'sms', a 6 or 7 digit Duo token, or press your YubiKey: <valid token>
[sudo] password for alice: NNNNNNN
WARNING: Juniper Network Connect support is experimental.
It will probably be superseded by Junos Pulse support.
password#2:
RESULT: Connected to the UCSF network [ip=128.218.43.53, hostname='',
org='AS5653 University of California San Francisco']

$ ucsf-vpn status
Connected to the UCSF network [ip=128.218.43.53, hostname='',
org='AS5653 University of California San Francisco']

$ ucsf-vpn details
{
  "ip": "128.218.43.53",
  "city": "San Francisco",
  "region": "California",
  "country": "US",
  "loc": "37.7631,-122.4590",
  "postal": "94143",
  "org": "AS5653 University of California San Francisco"
}
```

If you have problems connect using `ucsf-vpn`, make sure you are using the correct username and password, e.g. by testing to log in via the [UCSF VPN web proxy](https://remote.ucsf.edu/).

Alternatively to command-line options, the username and password can also be specified in file `~/.netrc` (or the file that environment variable `NETRC` specifies).  See `ucsf-vpn --help` for more details.  With a properly setup `~/.netrc` entry, you can connect to the UCSF VPN using:

```sh
$ ucsf-vpn connect
[sudo] password for alice: NNNNNNN
WARNING: Juniper Network Connect support is experimental.
It will probably be superseded by Junos Pulse support.
password#2:
```
after approving the push notification on your Duo Mobile app (the default is `--token push`).



## Disconnect
```sh
$ ucsf-vpn stop
RESULT: Killed local ('openconnect') VPN process
RESULT: Not connected to the UCSF network [ip=157.131.204.163, hostname='example.org',
org='AS12345 Example Organization']
```


## Usage
```sh
Connect to and Disconnect from the UCSF VPN

Usage:
 ucsf-vpn <command> [options]

Commands:
 start            Connect to UCSF VPN
 stop             Disconnect from UCSF VPN
 restart          Disconnect and reconnect to UCSF VPN
 toggle           Connect to or disconnect from UCSF VPN

 status           Display UCSF VPN connection status
 details          Display connection details
 log              Display the log file
 troubleshoot     Scan the log file for errors and more.

Options:
 --method <mth>   Either 'openconnect' (default) or 'pulse'.
 --user <user>    UCSF Active Directory ID (username)
 --pwd <pwd>      UCSF Active Directory ID password
 --token <token>  One-time two-factor authentication (2FA) token or method:
                   - 'prompt' (user is prompted to enter the token),
                   - 'push' ("approve and confirm" in Duo app; default),
                   - 'phone' (receive phone call and "press any key"),
                   - 'sms' (receive code via text message),
                   -  6 or 7 digit Duo token (from Duo app), or
                   -  44-letter YubiKey token ("press YubiKey").

 --server <host>  VPN server (default is remote.ucsf.edu)
 --realm <realm>  VPN realm (default is 'Dual-Factor Pulse Clients')
 --url <url>      VPN URL (default is https://{{server}}/pulse)

 --skip           If already fulfilled, skip command
 --force          Force running the command
 --verbose        Verbose output
 --help           This help
 --version        Display version

Environment variables:
 UCSF_VPN_METHOD  The default --method value ('openconnect').
 UCSF_VPN_TOKEN   The default --token value ('push').

Commands and Options for Pulse Security Client only (--method pulse):
 open-gui         Open the Pulse Secure GUI
 close-gui        Close the Pulse Secure GUI (and any VPN connections)

 --gui            Connect to VPN via Pulse Secure GUI (default)
 --no-gui         Connect to VPN via Pulse Secure CLI
 --speed <factor> Control speed of --gui interactions (default is 1.0)

Any other options are passed to Pulse Secure CLI as is (only --no-gui).

Examples:
 ucsf-vpn start
 ucsf-vpn start --user alice --token push
 UCSF_VPN_TOKEN=prompt ucsf-vpn start --user alice --pwd secrets
 ucsf-vpn start --token phone
 ucsf-vpn stop

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
  - `xdotool` (when using 'ucsf-vpn start --method pulse --gui')
  - No need for sudo rights

Pulse Secure GUI configuration:
Calling 'ucsf-vpn start --method pulse --gui' will, if missing,
automatically add a valid UCSF VPN connection to the Pulse Secure GUI
with the following details:
 - Name: UCSF
 - URL: https://remote.ucsf.edu/pulse
You may change the name to you own liking.

Troubleshooting:
* Verify your username and password at https://remote.ucsf.edu/.
  This should be your UCSF Active Directory ID (username); neither
  MyAccess SFID (e.g. 'sf*****') nor UCSF email address will work.
* If you are using the Pulse Secure client (`ucsf-vpn --method pulse`),
  - Make sure ports 4242 & 443 are not used by other processes
  - Make sure 'https://remote.ucsf.edu/pulse' is used as the URL
  - Run 'ucsf-vpn troubleshoot' to inspect the Pulse Secure logs

Useful resources:
* UCSF VPN information:
  - https://software.ucsf.edu/content/vpn-virtual-private-network
* UCSF Web-based VPN Interface:
  - https://remote.ucsf.edu/
* UCSF Two-Factory Authentication (2FA):
  - https://it.ucsf.edu/services/duo-two-factor-authentication
* UCSF Managing Your Passwords:
  - https://it.ucsf.edu/services/managing-your-passwords

Version: 4.2.0
Copyright: Henrik Bengtsson (2016-2019)
License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
Source: https://github.com/HenrikBengtsson/ucsf-vpn
```


## Installation

### `ucsf-vpn`

The `ucsf-vpn` script is distributed under GPL (>= 2.1) and the source
code is available at https://github.com/HenrikBengtsson/ucsf-vpn/.  To
"install" it, just do

```
$ curl -O https://raw.githubusercontent.com/HenrikBengtsson/ucsf-vpn/master/bin/ucsf-vpn
$ chmod ugo+x ucsf-vpn
```


## OpenConnect

In August 2017, the UCSF VPN server was updated such that it no longer works with OpenConnect (< 7.08).  Because of this, `uscf vpn` requires OpenConnect (>= 7.08).

OpenConnect (>= 7.08) is available on for instance Ubuntu 18.04 LTS (Bionic Beaver), but not on older LTS version.  For instance, Ubuntu 16.04 (Xenial Xerus) only provides OpenConnect 7.06, which [fails to connect with an error](https://github.com/HenrikBengtsson/ucsf-vpn/issues/4).  [There is a confirmed way to force install this](https://github.com/HenrikBengtsson/ucsf-vpn/issues/4) on to Ubuntu 16.04 from the Ubuntu 17.04 (Zesty) distribution, but it is not clear whether such an installation leaves the system in a stable state or not.  Moreover, due to library dependencies, it appears not possible to have OpenConnect 7.08 and Pulse Secure 5.3-3 installed at the same time.


## Pulse Secure Client

If you don't have OpenConnect (>= 7.08) you can use `ucsf vpn --method pulse` (or set environment variable `UCSF_VPN_METHOD=pulse`) to connect to the UCSF VPN using the Junos Pulse Secure client (Pulse Secure, LLC).  That software, which is a **closed-source proprietary software** (*), can be downloaded from UCSF website:

* https://software.ucsf.edu/content/vpn-virtual-private-network

Access to that page requires UCSF MyAccess Login (but no UCSF VPN).

Note: `ucsf-vpn --method pulse` is just a convenient wrapper script around the Pulse Secure client.  It is assumed that `pulsesvc` is available under `/usr/local/pulse/`. If not, set `PULSEPATH` to the folder where it is installed.


## Privacy

The `ucsf-vpn` software uses the https://ipinfo.io/ service to infer whether
a VPN connection is established or not, and to provide you with details on
your public internet connection.  The software does _not_ collect or attempt
to collect any of your UCSF credentials.