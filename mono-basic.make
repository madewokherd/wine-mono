MONO_BASIC_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono-basic)

$(SRCDIR)/mono-basic/build/config.make: $(SRCDIR)/mono-basic/configure $(SRCDIR)/mono-basic.make $(BUILDDIR)/mono-unix/.installed
	cd $(SRCDIR)/mono-basic && $(MONO_ENV) ./configure --prefix=$(BUILDDIR_ABS)/mono-basic-install

$(SRCDIR)/mono-basic/.built: $(SRCDIR)/mono-basic/build/config.make $(MONO_BASIC_SRCS) $(BUILDDIR)/.dir
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/mono-basic PROFILE_VBNC_FLAGS=/sdkpath:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.5-api
	touch $@

$(SRCDIR)/mono-basic/.installed: $(SRCDIR)/mono-basic/.built $(BUILDDIR)/.dir
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/mono-basic PROFILE_VBNC_FLAGS=/sdkpath:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.5-api install
	touch $@
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/mono-basic/.installed

mono-basic-image: $(SRCDIR)/mono-basic/.installed
	mkdir -p $(IMAGEDIR)/lib
	$(CP_R) $(BUILDDIR)/mono-basic-install/lib/mono $(IMAGEDIR)/lib
.PHONY: mono-basic-image
imagedir-targets: mono-basic-image

# FIXME: make clean for mono-basic source tree?
clean-build-mono-basic:
	rm -rf $(BUILDDIR)/mono-basic-install
.PHONY: clean-build-mono-basic
clean-build: clean-build-mono-basic

