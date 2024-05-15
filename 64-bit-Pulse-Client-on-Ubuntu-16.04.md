# 64-bit Pulse Client on Ubuntu 16.04

## Installation Notes
```sh
$ sudo dpkg -i ps-pulse-linux-5.3r3.0-b1021-ubuntu-debian-64-bit-installer.deb 
[sudo] password for hb: 
Selecting previously unselected package pulse.
(Reading database ... 506907 files and directories currently installed.)
Preparing to unpack ps-pulse-linux-5.3r3.0-b1021-ubuntu-debian-64-bit-installer.deb ...
Unpacking pulse (5.3R3-553) ...
Setting up pulse (5.3R3-553) ...
Please execute below commands to install missing dependent packages manually
apt-get install libwebkitgtk-1.0-0
apt-get install libproxy1-plugin-webkit

OR
You can install the missing dependency packages by running the below script 
  /usr/local/pulse/PulseClient_x86_64.sh install_dependency_packages

Please refer /usr/local/pulse/README for instructions to launch the Pulse Client


$ sudo apt-get install libwebkitgtk-1.0-0
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following additional packages will be installed:
  libjavascriptcoregtk-1.0-0
The following NEW packages will be installed:
  libjavascriptcoregtk-1.0-0 libwebkitgtk-1.0-0
0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
Need to get 9,439 kB of archives.
After this operation, 40.2 MB of additional disk space will be used.
Do you want to continue? [Y/n] 
Get:1 http://us.archive.ubuntu.com/ubuntu xenial-updates/universe amd64 libjavascriptcoregtk-1.0-0 amd64 2.4.11-0ubuntu0.1 [1,851 kB]
Get:2 http://us.archive.ubuntu.com/ubuntu xenial-updates/universe amd64 libwebkitgtk-1.0-0 amd64 2.4.11-0ubuntu0.1 [7,587 kB]
Fetched 9,439 kB in 5s (1,801 kB/s)             
Selecting previously unselected package libjavascriptcoregtk-1.0-0:amd64.
(Reading database ... 506913 files and directories currently installed.)
Preparing to unpack .../libjavascriptcoregtk-1.0-0_2.4.11-0ubuntu0.1_amd64.deb ...
Unpacking libjavascriptcoregtk-1.0-0:amd64 (2.4.11-0ubuntu0.1) ...
Selecting previously unselected package libwebkitgtk-1.0-0:amd64.
Preparing to unpack .../libwebkitgtk-1.0-0_2.4.11-0ubuntu0.1_amd64.deb ...
Unpacking libwebkitgtk-1.0-0:amd64 (2.4.11-0ubuntu0.1) ...
Processing triggers for libc-bin (2.23-0ubuntu9) ...
Setting up libjavascriptcoregtk-1.0-0:amd64 (2.4.11-0ubuntu0.1) ...
Setting up libwebkitgtk-1.0-0:amd64 (2.4.11-0ubuntu0.1) ...
Processing triggers for libc-bin (2.23-0ubuntu9) ...


$ sudo dpkg -i ps-pulse-linux-5.3r3.0-b1021-ubuntu-debian-64-bit-installer.deb 
(Reading database ... 506917 files and directories currently installed.)
Preparing to unpack ps-pulse-linux-5.3r3.0-b1021-ubuntu-debian-64-bit-installer.deb ...
Do you want to clean up the connection store? [Yy/Nn] 

Unpacking pulse (5.3R3-553) over (5.3R3-553) ...
Setting up pulse (5.3R3-553) ...
Please execute below commands to install missing dependent packages manually
apt-get install libproxy1-plugin-webkit

OR
You can install the missing dependency packages by running the below script 
  /usr/local/pulse/PulseClient_x86_64.sh install_dependency_packages

Please refer /usr/local/pulse/README for instructions to launch the Pulse Client


$ sudo apt-get install libproxy1-plugin-webkit
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following packages were automatically installed and are no longer required:
  libllvm3.8 libmircommon5 linux-headers-4.4.0-31 linux-headers-4.4.0-31-generic linux-headers-4.4.0-59
  linux-headers-4.4.0-59-generic linux-headers-4.4.0-83 linux-headers-4.4.0-83-generic linux-headers-4.4.0-87
  linux-headers-4.4.0-87-generic linux-headers-4.4.0-89 linux-headers-4.4.0-89-generic linux-headers-4.4.0-91
  linux-headers-4.4.0-91-generic linux-headers-4.4.0-92 linux-headers-4.4.0-92-generic linux-headers-4.4.0-93
  linux-headers-4.4.0-93-generic linux-headers-4.4.0-96 linux-headers-4.4.0-96-generic linux-image-4.4.0-31-generic
  linux-image-4.4.0-59-generic linux-image-4.4.0-83-generic linux-image-4.4.0-87-generic linux-image-4.4.0-89-generic
  linux-image-4.4.0-91-generic linux-image-4.4.0-92-generic linux-image-4.4.0-93-generic linux-image-4.4.0-96-generic
  linux-image-extra-4.4.0-31-generic linux-image-extra-4.4.0-59-generic linux-image-extra-4.4.0-83-generic
  linux-image-extra-4.4.0-87-generic linux-image-extra-4.4.0-89-generic linux-image-extra-4.4.0-91-generic
  linux-image-extra-4.4.0-92-generic linux-image-extra-4.4.0-93-generic linux-image-extra-4.4.0-96-generic snap-confine
  ubuntu-core-launcher
Use 'sudo apt autoremove' to remove them.
The following NEW packages will be installed:
  libproxy1-plugin-webkit
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 9,192 B of archives.
After this operation, 43.0 kB of additional disk space will be used.
Get:1 http://us.archive.ubuntu.com/ubuntu xenial/universe amd64 libproxy1-plugin-webkit amd64 0.4.11-5ubuntu1 [9,192 B]
Fetched 9,192 B in 0s (36.6 kB/s)                   
Selecting previously unselected package libproxy1-plugin-webkit:amd64.
(Reading database ... 506917 files and directories currently installed.)
Preparing to unpack .../libproxy1-plugin-webkit_0.4.11-5ubuntu1_amd64.deb ...
Unpacking libproxy1-plugin-webkit:amd64 (0.4.11-5ubuntu1) ...
Setting up libproxy1-plugin-webkit:amd64 (0.4.11-5ubuntu1) ...


$ sudo dpkg -i ps-pulse-linux-5.3r3.0-b1021-ubuntu-debian-64-bit-installer.deb 
(Reading database ... 506918 files and directories currently installed.)
Preparing to unpack ps-pulse-linux-5.3r3.0-b1021-ubuntu-debian-64-bit-installer.deb ...
Do you want to clean up the connection store? [Yy/Nn] 

Unpacking pulse (5.3R3-553) over (5.3R3-553) ...
Setting up pulse (5.3R3-553) ...
Please refer /usr/local/pulse/README for instructions to launch the Pulse Client
```

# Testing
The following works to connect to the VPN:
```sh
$ /usr/local/pulse/pulsesvc -h remote.ucsf.edu -r "Single-Factor Pulse Clients" -u <USER> -p <PWD>
```
So does:
```sh
$ export LD_LIBRARY_PATH=/usr/local/pulse
$ /usr/local/pulse/pulseUi
```
and setting up the connection and the clicking 'Connect'.
