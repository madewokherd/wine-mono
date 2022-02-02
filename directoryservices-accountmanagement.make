DIRECTORYSERVICES_ACCOUNTMANAGEMENT_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/external/corefx/src/System.DirectoryServices.AccountManagement)

$(SRCDIR)/directoryservices-accountmanagement/.built: $(BUILDDIR)/mono-unix/.installed $(WINFORMS_DATAVISUALIZATION_SRCS) directoryservices-accountmanagement/Makefile $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/directoryservices-accountmanagement/.built

System.DirectoryServices.AccountManagement.dll: $(SRCDIR)/directoryservices-accountmanagement/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/directoryservices-accountmanagement/System.DirectoryServices.AccountManagement.dll -root $(IMAGEDIR)/lib
.PHONY: System.DirectoryServices.AccountManagement.dll
imagedir-targets: System.DirectoryServices.AccountManagement.dll

clean-directoryservices-accountmanagement:
	$(MAKE) -C $(SRCDIR)/directoryservices-accountmanagement clean
.PHNOY: clean-directoryservices-accountmanagement
clean: clean-directoryservices-accountmanagement
