WINFORMS_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/winforms)

# dotnet core winforms
$(SRCDIR)/winforms/src/Accessibility/src/.built: $(BUILDDIR)/mono-unix/.installed $(WINFORMS_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/winforms/src/System.Windows.Forms/src/.built: $(SRCDIR)/winforms/src/Accessibility/src/.built $(BUILDDIR)/mono-unix/.installed $(WINFORMS_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

ifeq (1,$(ENABLE_DOTNET_CORE_WINFORMS))
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/winforms/src/Accessibility/src/.built
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/winforms/src/System.Windows.Forms/src/.built

Accessibility.dll: $(SRCDIR)/winforms/src/Accessibility/src/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/winforms/src/Accessibility/src/Accessibility.dll -root $(IMAGEDIR)/lib
.PHONY: Accessibility.dll
imagedir-targets: Accessibility.dll

System.Windows.Forms.dll: $(SRCDIR)/winforms/src/System.Windows.Forms/src/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/winforms/src/System.Windows.Forms/src/System.Windows.Forms.dll -root $(IMAGEDIR)/lib
.PHONY: System.Windows.Forms.dll
imagedir-targets: System.Windows.Forms.dll
endif

