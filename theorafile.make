THEORAFILE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/Theorafile)

define MINGW_TEMPLATE +=

# libtheorafile
$$(BUILDDIR)/Theorafile-$(1)/.built: $$(THEORAFILE_SRCS) $$(BUILDDIR)/.dir $$(MINGW_DEPS)
	mkdir -p $$(BUILDDIR)/Theorafile-$(1)
	+$$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR_ABS)/Theorafile-$(1) "CC=$$(MINGW_$(1))-gcc" -f $$(SRCDIR_ABS)/FNA/lib/Theorafile/Makefile
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/Theorafile-$(1)/.built

libtheorafile-$(1).dll: $$(BUILDDIR)/Theorafile-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/Theorafile-$(1)/libtheorafile.dll" "$$(IMAGEDIR)/lib/libtheorafile-$(1).dll"
.PHONY: libtheorafile-$(1).dll
imagedir-targets: libtheorafile-$(1).dll

clean-build-Theorafile-$(1):
	rm -rf $$(BUILDDIR)/Theorafile-$(1)
.PHONY: clean-build-Theorafile-$(1)
clean-build: clean-build-Theorafile-$(1)

endef

