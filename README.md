# UCSF VPN client (Linux)

The `ucsf-vpn` script is a Linux-only tool for connecting to and disconnecting from the UCSF VPN server.  It is based on the official UCSF instructions provided by the [UCSF IT](http://it.ucsf.edu/services/vpn) with additional instructions obtained through private communication.

## Connect
```sh
$ ucsf-vpn start --user=alice --pwd secrets
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

Alternatively to command-line options, the username and password can also be specified in file `~/.ucsfvpnrc`.  See `ucsf-vpn --help` for more details.


## Disconnect
```sh
$ ucsf-vpn stop
RESULT: Killed local VPN process
RESULT: Not connected to the UCSF network [example.org (93.184.216.34)]
```


## Usage
```sh
$ ucsf-vpn --help
Connect and Disconnect to the UCSF VPN

Usage:
 ucsf-vpn (start|restart|stop|toggle|status|details) [options]

Commands:
 start-gui      Open the Pulse Secure GUI
 start          Connects to UCSF VPN
 stop           Disconnects from UCSF VPN
 restart        Disconnects and reconnects to UCSF VPN
 toggle         Connects to or disconnects from UCSF VPN
 status         Displays UCSF VPN connection status
 details        Displays connection details

Options:
 --user         UCSF VPN username
 --pwd          UCSF VPN password
 --server       VPN server (defaults to remote.ucsf.edu)
 --skip         If already fulfilled, skip command
 --force        Force running the command
 --verbose      Verbose output
 --help         This help
 --version      Display version

Any other options are passed to Pulse Secure as is.

Example:
 ucsf-vpn start --user=alice --pwd secrets
 ucsf-vpn stop

User credentials:
The default values for --user and --pwd can be specified in
~/.ucsfvpnrc using one <key>=<value> pair per line. For example:

  user=alice
  pwd=secrets

For security, the ~/.ucsfvpnrc file should be readable only by the
user/owner of the file.  If not, then 'ucsf-vpn start' will set
its permission accordingly (by calling chmod go-rwx ~/.ucsfvpnrc).

Requirements:
* Junos Pulse Secure client (>= 5.3) (installed: 5.3-2-Build422)
* Ports 4242 (UDP) and 443 (TCP)
* curl
* No need for sudo rights to run :)

Troubleshooting:
* Verify your username and password at https://remote.ucsf.edu/.
* Make sure ports 4242 & 443 are not used by other processes

See also:
* https://remote.ucsf.edu/
* https://software.ucsf.edu/content/vpn-virtual-private-network
Version: 2.0.0
Copyright: Henrik Bengtsson (2016-2017)
License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
Source: https://github.com/HenrikBengtsson/ucsf-vpn
```


## Installation

The `ucsf-vpn` script is distributed under GPL (>= 2.1) and the source
code is available at https://github.com/HenrikBengtsson/ucsf-vpn/.  To
"install" it, just do

```
$ curl -O https://raw.githubusercontent.com/HenrikBengtsson/ucsf-vpn/master/bin/ucsf-vpn
$ chmod ugo+x ucsf-vpn
```

Importantly, `ucsf-vpn` is just a convenient wrapper script around the Junos
Pulse Secure client (Pulse Secure, LLC), which it expect to be available
as `/usr/local/pulse/pulsesvc`.
This software, which is a **closed-source proprietary software** (*),
can be downloaded from UCSF website:

* https://software.ucsf.edu/content/vpn-virtual-private-network

Access to that page requires UCSF MyAccess Login (but no UCSF VPN).

(*) In August 2017, the UCSF VPN server was updated such that it no longer
    works with the open-source OpenConnect client.


## Privacy

The `ucsf-vpn` software uses the https://ipinfo.io/ service to infer whether
a VPN connection is established or not, and to provide you with details on
your public internet connection.  The software does _not_ collect or attempt to collect any of your UCSF
credentials.
