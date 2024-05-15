# Pulse Secure - Temporary Notes

These notes will eventually make it into the README or a separate INSTALL file.

## Requirements

The [Pulse Secure client needs the following ports](https://kb.pulsesecure.net/articles/Pulse_Secure_Article/KB21762) in order to successfully communicate with Network Connection and to connect the UCSF VPN server:

* UDP port 4242 on loopback address
* TCP port 443

"The VPN tunneling option provides secure, SSL-based network-level remote access to all enterprise application resources using the device over port 443. Port 4242 is used for IPC communication between the VPN tunneling service and the VPN tunnel executable on the client PC."


## Running

### Pulse Secure GUI

To launching the Pulse Secure GUI from the command line, use:
```sh
export PATH="/usr/local/pulse:${PATH}"
export LD_LIBRARY_PATH="/usr/local/pulse:${LD_LIBRARY_PATH}"
pulseUi
```

### Pulse Secure Command-Line Client

The Pulse Secure command-line client can be launched as:
```sh
$ /usr/local/pulse/pulsesvc -h remote.ucsf.edu -r "Single-Factor Pulse Clients" -u ${MYACCESS_USER} -o ${MYACCESS_PWD}
```


### Logs
The Pulse log can be found in `~/.pulse_secure/pulse/pulsesvc.log`.  For an example of the log from a successful connection, see [Pulse Secure: Successful connection](https://github.com/HenrikBengtsson/ucsf-vpn/wiki/Pulse-Secure:-Successful-connection).

## Installation

### Downloads
Closed-source binaries for the Junos Pulse Secure client is available for RedHat and Debian Linux distributions. 
 They can be downloaded from [software.ucsf.edu](https://software.ucsf.edu/content/vpn-virtual-private-network) ([access via browser-based UCSF VPN](https://remote.ucsf.edu/content/,DanaInfo=software.ucsf.edu,SSL,SSO=U+vpn-virtual-private-network)), which requires MyAccess login.

```sh
$ md5sum pulse-5.3R2.i386.*
a787628f87887b173bd7999aaefe0532  pulse-5.3R2.i386.deb
c79448954217813c53cef467c985ba2f  pulse-5.3R2.i386.rpm
```

### Installing on Debian

Before trying to install Pulse on Debian, make sure that 32-bit packages are found:
```sh
$ sudo dpkg --add-architecture i386
$ sudo apt update
```
Then, run:
```sh
$ sudo dpkg -i pulse-5.3R2.i386.deb
$ /usr/local/pulse/PulseClient.sh install_dependency_packages
$ sudo dpkg -i pulse-5.3R2.i386.deb
[...]
(Reading database ... 409579 files and directories currently installed.)
Preparing to unpack pulse-5.3R2.i386.deb ...
Do you want to clean up the connection store? [Yy/Nn] y
Unpacking pulse (5.3) over (5.3) ...

Setting up pulse (5.3) ...
Please refer /usr/local/pulse/README for instructions to launch the Pulse Client
$
```

All Pulse software and libraries are installed in `/usr/local/pulse/`;
```sh
$ /usr/local/pulse/pulsesvc --version
Pulse Secure Network Connect client for Linux.
Version         : 5.3
Release Version : 5.3-2-Build422
Build Date/time : Jun  6 2017 21:29:46
Copyright 2016 Pulse Secure

$ cat /usr/local/pulse/version.txt
Version: 5.3R2
Build Number: 422
```

File checksums:
```r
md5sum /usr/local/pulse/*
md5sum: /usr/local/pulse/html: Is a directory
469339cd4657f30ae25e750b37d3ee25  /usr/local/pulse/libpulseui.so
04951d1ad6cf8755ba6cc6c8c8218a8f  /usr/local/pulse/libpulseui.so_centos_6
80326d084f663a819fc34ad7a019b2d2  /usr/local/pulse/libpulseui.so_centos_7
d79df1b639f7528689080de743117a35  /usr/local/pulse/postinstall.log
f1e13d9720aae0c034b09d0a4547555f  /usr/local/pulse/PulseClient.sh
a03ffbd199ddc62ed5a458b7821e559a  /usr/local/pulse/pulsediag
7b2a2f902fea218f73d479b05babe7b6  /usr/local/pulse/pulsesvc
012116af743dae9d119c5f99c71bc1c1  /usr/local/pulse/pulse.tgz
1c52b5112a408d28f96da26e7e21e2e6  /usr/local/pulse/pulseUi
1e1145d748139492bc953c405d4e3d0f  /usr/local/pulse/pulseUi_centos_6
646f2b02f992e9f3f9e7915552c7e65b  /usr/local/pulse/pulseUi_centos_7
262d13d3f5d5cee5686de36b8b05d2f6  /usr/local/pulse/pulseutil
a0c9489aaee4d7df935c7b7a8d90b6a9  /usr/local/pulse/README
8a4da1b467ecabcadc2c19a9e59c5913  /usr/local/pulse/version.txt
```

