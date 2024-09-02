.PHONY: docs
docs: docs/index.html

docs/index.html: config.ld *.lua
	@ldoc --date '' .
	@missing=0; for f in *.lua; do if [[ ! -e "docs/modules/$${f%%.lua}.html" ]] then echo "Missing docs: $$f"; missing=1; fi; done; exit $$missing
