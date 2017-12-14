2017-12-07: Two-factor authentication (2FA) is now required in order to connect to the UCSF VPN.

2017-12-09: `ucsf-vpn start` will now prompt for the 2FA token (Duo or YubiKey) and then submit user credentials and the 2FA token via the Pulse Secure GUI.

If anyone can figure out a solution for passing also the 2FA passcode via the Pulse command-line client, please drop a note in the [issue tracker](https://github.com/HenrikBengtsson/ucsf-vpn/issues).

---


[![Build Status](https://travis-ci.org/HenrikBengtsson/ucsf-vpn.svg?branch=develop)](https://travis-ci.org/HenrikBengtsson/ucsf-vpn)

# UCSF VPN client (Linux)

The `ucsf-vpn` script is a Linux-only tool for connecting to and disconnecting from the UCSF VPN server.  It is based on the official UCSF instructions provided by the [UCSF IT](https://it.ucsf.edu/services/vpn) with additional instructions obtained through private communication.

## Connect
```sh
$ ucsf-vpn start --user alice --pwd secrets
Enter 6-digit Duo token or press your YubiKey: <valid token>
RESULT: Connected to the UCSF network [otp477510ots.ucsf.edu (128.218.42.138)]

$ ucsf-vpn status
Connected to the UCSF network [otp477510ots.ucsf.edu (128.218.42.138)]

$ ucsf-vpn details
{
  "ip": "128.218.42.138",
  "hostname": "otp477510ots.ucsf.edu",
  "city": "San Francisco",
  "region": "California",
  "country": "US",
  "loc": "37.7631,-122.4586",
  "org": "AS5653 University of California San Francisco",
  "postal": "94143"
}
```

If you have problems connect using `ucsf-vpn`, make sure you are using the correct username and password, e.g. by testing to log in via the [UCSF VPN web proxy](https://remote.ucsf.edu/).

Alternatively to command-line options, the username and password can also be specified in file `~/.netrc` (or the file that environment variable `NETRC` specifies).  See `ucsf-vpn --help` for more details.


## Disconnect
```sh
$ ucsf-vpn stop
RESULT: Killed local VPN process
RESULT: Not connected to the UCSF network [example.org (93.184.216.34)]
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

 open-gui         Open the Pulse Secure GUI
 close-gui        Close the Pulse Secure GUI (and any VPN connections)

Options:
 --user <user>    UCSF Active Directory ID (username)
 --pwd <pwd>      UCSF Active Directory ID password
 --token <token>  One-time two-factor authentication (2FA) token (Duo or
                  YubiKey). If 'true' (default), user is prompted to enter
                  the token. If 'push', authentication is done via
                  Duo Push (approve and confirm in Duo app). If 'phone',
                  authenatication is done by a phone call ("press any key").
                  If 'false', 2FA is not used.

 --gui            Connect to VPN via Pulse Secure GUI (default)
 --no-gui         Connect to VPN via Pulse Secure CLI
 --speed <factor> Control speed of --gui interactions (default is 1.0)

 --server <host>  VPN server (default is remote.ucsf.edu)
 --realm <realm>  VPN realm (default is 'Dual-Factor Pulse Clients')
 --url <url>      VPN URL (default is https://{{server}}/pulse)
                  (only used with --gui)

 --skip           If already fulfilled, skip command
 --force          Force running the command
 --verbose        Verbose output
 --help           This help
 --version        Display version

Any other options are passed to Pulse Secure CLI as is (only --no-gui).

Examples:
 ucsf-vpn start --user alice --token push
 ucsf-vpn start --user alice --pwd secrets --token true
 ucsf-vpn start --token phone
 ucsf-vpn start
 ucsf-vpn stop

User credentials:
If user credentials (--user and --pwd) are neither specified nor given
in ~/.netrc, then you will be prompted to enter them. To specify them
in ~/.netrc file, use the following:

  machine remote.ucsf.edu
      login alice
      password secrets

For security, the ~/.netrc file should be readable only by
the user / owner of the file. If not, then 'ucsf-vpn start' will
set its permission accordingly (by calling chmod go-rwx ~/.netrc).

Requirements:
* Junos Pulse Secure client (>= 5.3) (installed: 5.3-3-Build553)
* Ports 4242 (UDP) and 443 (TCP)
* `curl`
* `xdotool` (when using 'ucsf-vpn start --gui')
* No need for sudo rights to run :)

Pulse Secure GUI configuration:
Calling 'ucsf-vpn start --gui' will, if missing, automatically add a valid
UCSF VPN connection to the Pulse Secure GUI with the following details:
 - Name: UCSF
 - URL: https://remote.ucsf.edu/pulse
You may change the name to you own liking.

Troubleshooting:
* Verify your username and password at https://remote.ucsf.edu/.
  This should be your UCSF Active Directory ID (username); neither
  MyAccess SFID (e.g. 'sf*****') nor UCSF email address will work.
* Make sure ports 4242 & 443 are not used by other processes
* If you are using the Pulse Secure GUI (`ucsf-vpn open-gui`), use
  'https://remote.ucsf.edu/pulse' as the URL when adding a new
  connection.
* Run 'ucsf-vpn troubleshoot' to inspect the Pulse Secure logs and more.

Useful resources:
* UCSF VPN information:
  - https://software.ucsf.edu/content/vpn-virtual-private-network
* UCSF Web-based VPN Interface:
  - https://remote.ucsf.edu/
* UCSF Two-Factory Authentication (2FA):
  - https://it.ucsf.edu/services/duo-two-factor-authentication
* UCSF Active Directory Account Manager:
  - https://pwmanage.ucsf.edu/pm/

Version: 3.1.1-9000
Copyright: Henrik Bengtsson (2016-2017)
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

### Pulse Secure client

Importantly, `ucsf-vpn` is just a convenient wrapper script around the Junos
Pulse Secure client (Pulse Secure, LLC), which it expect to be available
as `/usr/local/pulse/pulsesvc`.
This software, which is a **closed-source proprietary software** (*),
can be downloaded from UCSF website:

* https://software.ucsf.edu/content/vpn-virtual-private-network

Access to that page requires UCSF MyAccess Login (but no UCSF VPN).


## OpenConnect?

In August 2017, the UCSF VPN server was updated such that it no longer works with OpenConnect (< 7.08).

For instance, users on Ubuntu 16.04 (Xenial) only gets OpenConnect 7.06, which [fails to connect with an error](https://github.com/HenrikBengtsson/ucsf-vpn/issues/4).  It has later been found that this was fixed in OpenConnect 7.08.  [There is a confirmed way to force install this](https://github.com/HenrikBengtsson/ucsf-vpn/issues/4) on to Ubuntu 16.04 from the Ubuntu 17.04 (Zesty) distribution, but it is not clear whether such an installation leaves the system in a stable state or not.  Moreover, due to library dependencies, it appears not possible to have OpenConnection 7.08 and Pulse Secure 5.3-3 installed at the same time.


## Privacy

The `ucsf-vpn` software uses the https://ipinfo.io/ service to infer whether
a VPN connection is established or not, and to provide you with details on
your public internet connection.  The software does _not_ collect or attempt to collect any of your UCSF
credentials.