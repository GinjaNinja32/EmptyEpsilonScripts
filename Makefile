SHELL := /bin/bash

.PHONY: docs
docs: docs/index.html

docs/index.html: config.ld *.lua README.md
	@ldoc --fatalwarnings --date '' .
	@missing=0; for f in *.lua; do if [[ ! -e "docs/modules/$${f%%.lua}.html" ]]; then echo "Missing docs: $$f"; missing=1; fi; done; exit $$missing

ci:
	@cd .. && lua ./gn32/test/all.lua
