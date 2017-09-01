# UPDATE 2017-09-01

As of end of August 2017, access to UCSF VPN via OpenConnect is broken (and probably no longer supported).  Because of this, **the current implementation of `ucsf-vpn` no longer works**.  Instead, the officially recommended method to connect to the UCSF VPN on Linux is via the (closed-source) [Junos Pulse Secure client](https://software.ucsf.edu/content/vpn-virtual-private-network) ([access via browser-based UCSF VPN](https://remote.ucsf.edu/content/,DanaInfo=software.ucsf.edu,SSL,SSO=U+vpn-virtual-private-network)), which is available for Debian and RedHat Linux distributions.

There are some very brief [installation notes](https://github.com/HenrikBengtsson/ucsf-vpn/wiki/Notes) on the wiki.  Please feel free to contribute whatever you think is useful.

The goal is to update this `ucsf-vpn` tool to support Pulse Secure from the command line, iff possible.

---

# UCSF VPN client (Linux)

The `uscf-vpn` script is a Linux-only tool for connecting to and disconnecting from the UCSF VPN server.  It is based on [the official UCSF instructions](https://it.ucsf.edu/sites/it.ucsf.edu/files/installopenconnect.pdf) provided by [UCSF IT](http://it.ucsf.edu/services/vpn).

## Connect
```sh
$ ucsf-vpn start --user=johndoe --pwd secrets
WARNING: Juniper Network Connect support is experimental.
It will probably be superseded by Junos Pulse support.
RESULT: Connected via the UCSF VPN network (your public IP is 128.218.43.111)

$ ucsf-vpn status
Connected via the UCSF VPN network (your public IP is 128.218.43.111)
```

If you have problems connect, you can confirm you are using the correct username and password via the USCF VPN web proxy (https://remote.ucsf.edu/).

Alternatively to command-line options, the username and password can also be specified in file `~/.ucsfvpnrc`.  See `ucsf-vpn --help` for more details.


## Disconnect
```sh
$ ucsf-vpn stop
RESULT: Not connected to the UCSF VPN network (your public IP is 73.93.141.38)

$ ucsf-vpn status
Not connected to the UCSF VPN network (your public IP is 73.93.141.38)
```


## Usage
```sh
$ ucsf-vpn --help
Connect and Disconnect to the UCSF VPN

Usage:
 ucsf vpn (start|restart|stop|toggle|status) [options]

Commands:
 start          Connects to UCSF VPN
 stop           Disconnects from UCSF VPN
 restart        Disconnects and reconnects to UCSF VPN
 toggle         Connects to or disconnects from UCSF VPN
 status         Displays UCSF VPN connection status

Options:
 --user         UCSF VPN username
 --pwd          UCSF VPN password
 --server       VPN server (defaults to remote.ucsf.edu)
 --skip         If already fullfilled, skip command
 --force        Force running the command
 --verbose      Verbose output
 --help         This help
 --version      Display version

Any other options are passed to openconnect as is.

Example:
 ucsf vpn start --user=johndoe --pwd secrets
 ucsf vpn stop

User credentials:
The default values for --user and --pwd can be specified in
~/.ucsfvpnrc using one <key>=<value> pair per line. For example:

  user=johndoe
  pwd=secret

For security, the ~/.ucsfvpnrc file should be readable only by
the user / owner of the file.  If not, then 'ucsf vpn start' will
set its permission accordingly (by calling chmod go-rwx ~/.ucsfvpnrc).


Installed dependencies and requirements:
* sudo rights
* openconnect 7.06 (requires >= 7.06)

Troubleshooting:
You can verify your username and password at https://remote.ucsf.edu/.

See also:
* https://remote.ucsf.edu/
* https://it.ucsf.edu/sites/it.ucsf.edu/files/installopenconnect.pdf

Version: 1.3.0
Copyright: Henrik Bengtsson (2016-2017)
License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
```


## Installation

```
$ mkdir ~/bin
$ cd bin
$ wget https://raw.githubusercontent.com/UCSF-CBC/ucsf-vpn/master/bin/ucsf-vpn
$ chmod ugo+x ucsf-vpn
```

You also need `openconnect` (>= 7.06) on you system, e.g.

* Debian / Ubuntu: `sudo apt install openconnect`
* Centos / RHEL: `sudo yum install openconnect`


## See also
* https://remote.ucsf.edu/
* https://it.ucsf.edu/sites/it.ucsf.edu/files/installopenconnect.pdf
