SHELL:=/bin/bash

README.md: README.md.tmpl announcement.md bin/ucsf-vpn
	bfr=`cat $<`; \
	help=`bin/ucsf-vpn --help`; \
	announcement=`cat announcement.md 2> /dev/null`; \
	bfr=`echo "$${bfr/\{\{ HELP \}\}/$$help}"`; \
	bfr=`echo "$${bfr/\{\{ ANNOUNCEMENT \}\}/$$announcement}"`; \
	echo "$$bfr" > $@
