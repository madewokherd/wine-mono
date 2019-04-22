
SRCDIR=$(dir $(MAKEFILE_LIST))
BUILDDIR=$(SRCDIR)
OUTDIR=$(SRCDIR)

MSI_VERSION=4.8.99

MONO_MAKEFILES=$(shell cd $(SRCDIR); find mono -name Makefile.am)

all:
	echo *** The makefile is a work in progress, please use build-winemono.sh for now ***
	false

$(SRCDIR)/mono/configure: $(SRCDIR)/mono/autogen.sh $(SRCDIR)/mono/configure.ac $(SRCDIR)/mono/libgc/autogen.sh $(SRCDIR)/mono/libgc/configure.ac $(MONO_MAKEFILES)
	cd $(SRCDIR)/mono; NOCONFIGURE=yes ./autogen.sh
