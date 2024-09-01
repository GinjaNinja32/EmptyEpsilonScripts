.PHONY: doc
doc: doc/index.html

doc/index.html: config.ld *.lua
	ldoc --date '' .
