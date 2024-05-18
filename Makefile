SHELL:=/bin/bash

all: build README.md shellcheck spelling

.PHONY: help

build:
	./build.sh


## Regenerate README.md
README.md: README.md.tmpl bin/ucsf-vpn
	@bfr=`cat $<`; \
	help=`bin/ucsf-vpn --help`; \
	bfr=`echo "$${bfr/\{\{ HELP \}\}/$$help}"`; \
	printf "$$bfr" > $@
	@echo "README.md"


.PHONY: test

## Check code using static-code analysis
shellcheck:
	echo "ShellCheck $$(shellcheck --version | grep version:)"
	cd src; shellcheck -x ucsf-vpn.sh vpnc/connect.d/ucsf-vpn-flavors.sh
	shellcheck bin/ucsf
	shellcheck bin/ucsf-vpn

codespell:
	codespell

## Check spelling
spelling:
	Rscript -e 'spelling::spell_check_files(c("NEWS.md", "README.md"), ignore = readLines("WORDLIST"))'

## Record asciinema screencast
asciinema-record:
	@rm -f ~/screencast.cast
	@cd ~ ; \
	asciinema rec -i 0.5 screencast.cast
	mv ~/screencast.cast screencast.cast

## Prune recorded asciinema screencast
asciinema-prune:
	@sed -i -E "s/$$USER@$$HOSTNAME/alice84@alice-laptop/g" screencast.cast
	@sed -i -E "s/'$$USER'/'alice84'/g" screencast.cast
	@sed -i -E "s/'$$HOSTNAME'/'alice-laptop'/g" screencast.cast
#	@sed -i -E "/file:[/][/]$$HOSTNAME/d" ~/screencast.cast
	@sed -i -E "/exit/d" screencast.cast
	@echo "Next, manually edit 'screencast.cast'"

## Play recorded asciinema screencast
asciinema-play:
	asciinema play screencast.cast

## Generate GIF of recorded asciinema screencast
screencast.gif: screencast.cast
	asciicast2gif -S 2 -h 12 -w 80 $< $@

## Display this help
help:
	@printf "Please use \`make <target>' where <target> is one of:\n\n"
	@awk '/^[a-zA-Z\-0-9_.]+:.*/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "%-25s %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
