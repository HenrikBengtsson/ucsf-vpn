# UCSF VPN client (Linux)

## Connect
```sh
ucsf-vpn start --user=johndoe --pwd secrets
```

## Disconnect
```sh
ucsf-vpn stop
```
## Usage
```sh
ucsf-vpn --help
Usage:
 ucsf-vpn (start|stop|status) [options]

Commands:
 start          Connects to UCSF VPN
 stop           Disconnects from UCSF VPN
 status         Displays UCSF VPN connection status

Options:
 --user         UCSF VPN username
 --pwd          UCSF VPN password
 --verbose      Verbose output
 --help         This help
 --version      Display version

Any other options are passed to openconnect as is.

Example:
 ucsf-vpn start --user=johndoe --pwd secrets
 ucsf-vpn stop

User credentials:
The default values for --user and --pwd can be specified in
~/.ucsfvpnrc using one <key>=<value> pair per line. For example:

  user=johndoe
  pwd=secret

For security, the ~/.ucsfvpnrc file should be readable only by
the user / owner of the file.  If not, then 'ucsf-vpn start' will
set its permission accordingly (by calling chmod go-rwx ~/.ucsfvpnrc).

Requirements:
* sudo rights
* openconnect (>= 7.06)

Troubleshooting:
You can verify your username and password at https://remote.ucsf.edu/.

See also:
* https://remote.ucsf.edu/
* https://it.ucsf.edu/sites/it.ucsf.edu/files/installopenconnect.pdf

Version: 3.0.0
Copyright: Henrik Bengtsson (2016)
License: GPL (>= 2.1) [https://www.gnu.org/licenses/gpl.html]
```

## See also
* https://remote.ucsf.edu/
* https://it.ucsf.edu/sites/it.ucsf.edu/files/installopenconnect.pdf
