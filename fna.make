FNA_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA)
FNA_NETSTUB_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA.NetStub)

# FNA
$(SRCDIR)/FNA/bin/Release/FNA.dll: $(BUILDDIR)/mono-unix/.installed $(FNA_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/FNA release
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/FNA/bin/Release/FNA.dll

FNA.dll: $(SRCDIR)/FNA/bin/Release/FNA.dll
	$(MONO_ENV) gacutil -i $(SRCDIR)/FNA/bin/Release/FNA.dll -root $(IMAGEDIR)/lib
.PHONY: FNA.dll
imagedir-targets: FNA.dll

clean-FNA:
	+$(MAKE) -C $(SRCDIR)/FNA clean
.PHONY: clean-FNA
clean: clean-FNA

$(SRCDIR)/FNA.NetStub/bin/Strongname/FNA.NetStub.dll: $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/FNA/bin/Release/FNA.dll $(FNA_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/FNA.NetStub
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/FNA.NetStub/bin/Strongname/FNA.NetStub.dll

FNA.NetStub.dll: $(SRCDIR)/FNA.NetStub/bin/Strongname/FNA.NetStub.dll
	$(MONO_ENV) gacutil -i $(SRCDIR)/FNA.NetStub/bin/Strongname/FNA.NetStub.dll -root $(IMAGEDIR)/lib
.PHONY: FNA.NetStub.dll
imagedir-targets: FNA.NetStub.dll

clean-FNA.NetStub:
	+$(MAKE) -C $(SRCDIR)/FNA.NetStub clean
.PHONY: clean-FNA.NetStub
clean: clean-FNA.NetStub

$(SRCDIR)/FNA/abi/.built: $(SRCDIR)/FNA/bin/Release/FNA.dll $(SRCDIR)/FNA.NetStub/bin/Strongname/FNA.NetStub.dll
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/FNA/abi
	touch $@
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/FNA/abi/.built

Microsoft.Xna.Framework.dll: $(SRCDIR)/FNA/abi/.built
	for i in $(SRCDIR)/FNA/abi/Microsoft.Xna.*.dll; do $(MONO_ENV) gacutil -i $$i -root $(IMAGEDIR)/lib; done
.PHONY: Microsoft.Xna.Framework.dll
imagedir-targets: Microsoft.Xna.Framework.dll

clean-FNA-abi:
	+$(MAKE) -C $(SRCDIR)/FNA/abi clean
.PHONY: clean-FNA-abi
clean: clean-FNA-abi

