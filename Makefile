.PHONY: doc
doc: doc/index.html

doc/index.html: *.lua
	ldoc .
