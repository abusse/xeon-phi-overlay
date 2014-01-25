DESTDIR ?=
EPREFIX ?=
PREFIX ?= $(EPREFIX)/usr

INSTALL_DIR  = install -m 755 -d
INSTALL_EXEC = install -m 755
PORTDIR ?= $(shell portageq envvar PORTDIR)
FNAMES = cross-emerge-ng
SITE = $(PREFIX)/share/crossdev/include/site
TOPDIR =

all:

install:
	$(INSTALL_DIR) $(DESTDIR)/$(PREFIX)/bin/ $(DESTDIR)/$(SITE)
	$(INSTALL_EXEC) $(FNAMES) $(DESTDIR)/$(PREFIX)/bin/
	sed -i -e s@__PREFIX__@$(PREFIX)@g $(DESTDIR)/$(PREFIX)/bin/cross-emerge-ng
	$(INSTALL_DIR) $(DESTDIR)/$(PREFIX)/share/crossdev/wrappers
	cp toolchain-wrapper $(DESTDIR)/$(PREFIX)/share/crossdev/wrappers/

.PHONY: all install
