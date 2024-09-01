.PHONY: docs
docs: docs/index.html

docs/index.html: config.ld *.lua
	ldoc --date '' .
