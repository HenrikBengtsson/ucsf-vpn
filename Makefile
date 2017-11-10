SHELL:=/bin/bash

README.md: README.md.tmpl bin/ucsf-vpn
	bfr=`cat $<`; \
	help=`bin/ucsf-vpn --help`; \
	echo "$${bfr/\{\{ HELP \}\}/$$help}" > $@
