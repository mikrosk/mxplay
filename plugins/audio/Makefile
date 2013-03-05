SUBDIRS = ace aon asap dspmod gt2 mgt mp2 mpg123 ntk snd xmp

default: release

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: clean
clean: $(SUBDIRS)
	rm -f *~ *.mxp aranym/* firebee/*

.PHONY: release
release: $(SUBDIRS)
