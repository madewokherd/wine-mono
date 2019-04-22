
SRCDIR=$(dir $(MAKEFILE_LIST))
BUILDDIR=$(SRCDIR)/build
OUTDIR=$(SRCDIR)

MINGW_x86=i686-w64-mingw32
MINGW_x86_64=x86_64-w64-mingw32

MSI_VERSION=4.8.99

SRCDIR_ABS=$(shell cd $(SRCDIR); pwd)
BUILDDIR_ABS=$(shell cd $(BUILDDIR); pwd)
OUTDIR_ABS=$(shell cd $(OUTDIR); pwd)

MONO_MAKEFILES=$(shell cd $(SRCDIR); find mono -name Makefile.am)

all:
	echo *** The makefile is a work in progress, please use build-winemono.sh for now ***
	false

$(SRCDIR)/mono/configure: $(SRCDIR)/mono/autogen.sh $(SRCDIR)/mono/configure.ac $(SRCDIR)/mono/libgc/autogen.sh $(SRCDIR)/mono/libgc/configure.ac $(MONO_MAKEFILES)
	cd $(SRCDIR)/mono; NOCONFIGURE=yes ./autogen.sh

$(BUILDDIR):
	mkdir $@

define MINGW_TEMPLATE =
$$(BUILDDIR)/mono-$(1): $$(BUILDDIR)
	mkdir $$@

$$(BUILDDIR)/mono-$(1)/Makefile: $$(BUILDDIR)/mono-$(1) $$(SRCDIR)/mono/configure
	cd $$(BUILDDIR)/mono-$(1); CPPFLAGS="-gdwarf-2 -gstrict-dwarf" $$(SRCDIR_ABS)/mono/configure --prefix="$$(BUILDDIR_ABS)/build-cross-$(1)-install" --build=$(shell $(SRCDIR)/mono/config.guess) --target=$$(MINGW_$(1)) --host=$$(MINGW_$(1)) --with-tls=none --disable-mcs-build --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG=false mono_cv_clang=no
	sed -e 's/-lgcc_s//' -i $$(BUILDDIR)/mono-$(1)/libtool
endef

$(eval $(call MINGW_TEMPLATE,x86))
$(eval $(call MINGW_TEMPLATE,x86_64))
