SYSTEM_SPEECH_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/System.Speech)

$(SRCDIR)/System.Speech/src/.built: $(BUILDDIR)/mono-unix/.installed $(SYSTEM_SPEECH_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/System.Speech/src/.built

System.Speech.dll: $(SRCDIR)/System.Speech/src/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/System.Speech/src/System.Speech.dll -root $(IMAGEDIR)/lib
.PHONY: System.Speech.dll
imagedir-targets: System.Speech.dll
