SHELL:=/bin/bash

README.md: README.md.tmpl announcement.md bin/ucsf-vpn
	@bfr=`cat $<`; \
	help=`bin/ucsf-vpn --help`; \
	announcement="`cat announcement.md 2> /dev/null`"; \
	bfr=`echo "$${bfr/\{\{ HELP \}\}/$$help}"`; \
	if [[ -n $$announcement ]]; then announcement="$$announcement\n\n---\n"; bfr=`echo "$${bfr/\{\{ ANNOUNCEMENT \}\}/$$announcement}"`; else bfr=`echo "$$bfr" | grep -vF "{{ ANNOUNCEMENT }}"`; fi; \
	printf "$$bfr" > $@
	@echo "README.md"


.PHONY: test

check:
	shellcheck bin/ucsf
	shellcheck bin/ucsf-vpn
