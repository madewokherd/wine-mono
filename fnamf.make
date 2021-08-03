FNAMF_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FNAMF)

define MINGW_TEMPLATE +=

# FNAMF
$$(BUILDDIR)/FNAMF-$(1)/.built: $$(FNAMF_SRCS) $$(BUILDDIR)/.dir $$(MINGW_DEPS)
	mkdir -p $$(BUILDDIR)/FNAMF-$(1)
	+$$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $$(MAKE) -C $$(BUILDDIR_ABS)/FNAMF-$(1) "CC=$$(MINGW_$(1))-gcc" -f $$(SRCDIR_ABS)/FNA/lib/FNAMF/Makefile SRCDIR=$$(SRCDIR_ABS)/FNA/lib/FNAMF
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/FNAMF-$(1)/.built

FNAMF-$(1).dll: $$(BUILDDIR)/FNAMF-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/FNAMF-$(1)/FNAMF.dll" "$$(IMAGEDIR)/lib/FNAMF-$(1).dll"
.PHONY: FNAMF-$(1).dll
imagedir-targets: FNAMF-$(1).dll

clean-build-FNAMF-$(1):
	rm -rf $$(BUILDDIR)/FNAMF-$(1)
.PHONY: clean-build-FNAMF-$(1)
clean-build: clean-build-FNAMF-$(1)

endef

