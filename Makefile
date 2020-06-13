SHELL:=/bin/bash

all: README.md check spelling

README.md: README.md.tmpl bin/ucsf-vpn
	@bfr=`cat $<`; \
	help=`bin/ucsf-vpn --help`; \
	bfr=`echo "$${bfr/\{\{ HELP \}\}/$$help}"`; \
	printf "$$bfr" > $@
	@echo "README.md"


.PHONY: test

check:
	echo "ShellCheck $$(shellcheck --version | grep version:)"
	shellcheck bin/ucsf
	shellcheck bin/ucsf-vpn

spell:
	Rscript -e 'spelling::spell_check_files(c("NEWS.md", "README.md"), ignore = readLines("WORDLIST"))'
