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

asciinema-record:
	@rm -f ~/screencast.cast
	@cd ~ ; \
	asciinema rec -i 0.5 screencast.cast
	mv ~/screencast.cast screencast.cast

asciinema-prune:
	@sed -i -E "s/$$USER@$$HOSTNAME/alice@alice-laptop/g" screencast.cast
	@sed -i -E "s/'$$USER'/'alice84'/g" screencast.cast
	@sed -i -E "s/'$$HOSTNAME'/'alice-laptop'/g" screencast.cast
#	@sed -i -E "/file:[/][/]$$HOSTNAME/d" ~/screencast.cast
	@sed -i -E "/exit/d" screencast.cast
	@echo "Next, manually edit 'screencast.cast'"

asciinema-play:
	asciinema play screencast.cast

screencast.gif:
	asciicast2gif -S 2 -h 12 -w 80 screencast.cast screencast.gif

