
.SUFFIXES: #disable all builtin rules

# configuration
SRCDIR:=$(dir $(MAKEFILE_LIST))
BUILDDIR=$(SRCDIR)/build
IMAGEDIR=$(SRCDIR)/image

ifeq ($(shell test -d $(SRCDIR)/output && echo y),y)
OUTDIR=$(SRCDIR)/output
else
OUTDIR=$(SRCDIR)
endif

TESTS_OUTDIR=$(OUTDIR)/tests

WINE=wine

COMPRESSOR=xz -9 -T0
COMPRESSED_SUFFIX=xz

ENABLE_DOTNET_CORE_WINFORMS=1
ENABLE_DOTNET_CORE_WPF=1
ENABLE_DOTNET_CORE_WPFGFX=1

ENABLE_DEBUG_SYMBOLS=0

-include user-config.make

MSI_VERSION=5.1.99

# variables
SRCDIR_ABS=$(shell cd $(SRCDIR); pwd)
BUILDDIR_ABS=$(shell cd $(BUILDDIR); pwd)
IMAGEDIR_ABS=$(shell cd $(IMAGEDIR); pwd)
OUTDIR_ABS=$(shell cd $(OUTDIR); pwd)

MONO_BIN_PATH=$(BUILDDIR_ABS)/mono-unix-install/bin
MONO_LD_PATH=$(BUILDDIR_ABS)/mono-unix-install/lib
MONO_GAC_PREFIX=$(BUILDDIR_ABS)/mono-unix-install
MONO_CFG_DIR=$(BUILDDIR_ABS)/mono-unix-install/etc
MONO_ENV=PATH="$(MONO_BIN_PATH):$$PATH" LD_LIBRARY_PATH="$(MONO_LD_PATH):$$LD_LIBRARY_PATH" MONO_GAC_PREFIX="$(MONO_GAC_PREFIX)" MONO_CFG_DIR="$(MONO_CFG_DIR)"

MINGW_ENV=$(and $(MINGW_PATH),PATH=$(MINGW_PATH):$$PATH)

CP_R=python $(SRCDIR_ABS)/tools/copy_recursive.py
RM_F=rm -f

# dependency checks
ifeq (,$(shell which $(WINE)))
$(error '$(WINE)' command not found. Please install wine or specify its location in the WINE variable)
endif

all: image targz msi tests tests-zip
.PHONY: all clean imagedir-targets tests tests-zip

define HELP_TEXT =
The following targets are defined:
	msi:	      Build wine-mono-$(MSI_VERSION)-x86.msi
	targz:	      Build wine-mono-$(MSI_VERSION)-x86.tar.gz
	tests:        Build the mono tests.
	test:         Build and run the mono tests.
	dev:          Build the runtime locally in image/ and configure $$WINEPREFIX to use it.
	System.dll:   Build a single dll and place it in the image/ directory.
	image:        Build the runtime locally image/ directory.
	dev-setup:    Configure $$WINEPREFIX to use the image/ directory.
endef

define newline =


endef

help:
	@echo -e '$(subst $(newline),\n,$(call HELP_TEXT))'

include llvm.make

dev-setup:
	for i in `$(WINE) uninstaller --list|grep '|||Wine Mono'|sed -e 's/|||.*$$//'`; do $(WINE) uninstaller --remove "$$i"; done
	$(WINE) msiexec /i '$(shell $(WINE) winepath -w $(IMAGEDIR)/support/winemono-support.msi)'
	$(WINE) reg add 'HKCU\Software\Wine\Mono' /v RuntimePath /d '$(shell $(WINE) winepath -w $(IMAGEDIR))' /f

dev: image
	+$(MAKE) dev-setup

$(BUILDDIR)/.dir:
	mkdir -p $(BUILDDIR)
	touch $(BUILDDIR)/.dir

clean-build:
	rm -f $(BUILDDIR)/.dir
	-rmdir $(BUILDDIR)
clean: clean-build
.PHONY: clean-build

# mingw targets
define MINGW_TEMPLATE =

ifeq (1,$(ENABLE_DEBUG_SYMBOLS))
INSTALL_PE_$(1)=cp
else
INSTALL_PE_$(1)=do_install () { cp "$$$$1" "$$$$2"; $$(MINGW_ENV) $$(MINGW_$(1))-strip "$$$$2"; }; do_install
endif

# installinf.exe
$$(BUILDDIR)/installinf-$(1).exe: $$(SRCDIR)/tools/installinf/installinf.c $$(MINGW_DEPS)
	$$(MINGW_ENV) $$(MINGW_$(1))-gcc $$< -lsetupapi -municode -o $$@

support-installinf-$(1): $$(BUILDDIR)/installinf-$(1).exe
	mkdir -p $$(IMAGEDIR)/support/
	$$(INSTALL_PE_$(1)) $$(BUILDDIR)/installinf-$(1).exe $$(IMAGEDIR)/support/installinf-$(1).exe
.PHONY: support-installinf-$(1)
imagedir-targets: support-installinf-$(1)
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/installinf-$(1).exe

clean-build-installinf-$(1):
	rm -rf $$(BUILDDIR)/installinf-$(1).exe
.PHONY: clean-build-installinf-$(1)
clean-build: clean-build-installinf-$(1)

endef

include mono.make
include mono-basic.make
include fna.make
include faudio.make
include sdl2.make
include sdl2-image.make
include theorafile.make
include mojoshader.make
include winforms.make
include winforms-datavisualization.make
include wpf.make
include support.make

$(eval $(call MINGW_TEMPLATE,x86))
$(eval $(call MINGW_TEMPLATE,x86_64))

$(BUILDDIR)/set32only.exe: $(SRCDIR)/tools/set32only/set32only.c $(MINGW_DEPS)
	$(MINGW_ENV) $(MINGW_x86_64)-gcc -municode -Wall $< -o $@

clean-build-set32only:
	rm -rf $(BUILDDIR)/set32only.exe
.PHONY: clean-build-set32only
clean-build: clean-build-set32only

$(BUILDDIR)/run-tests.exe: $(SRCDIR)/tools/run-tests/run-tests.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc $(SRCDIR)/tools/run-tests/run-tests.cs -out:$(BUILDDIR)/run-tests.exe

clean-build-runtestsexe:
	rm -rf $(BUILDDIR)/run-tests.exe
.PHONY: clean-build-runtestsexe
clean-build: clean-build-runtestsexe

tests: $(BUILDDIR)/run-tests.exe
	-mkdir -p $(TESTS_OUTDIR)
	cp $(BUILDDIR)/run-tests.exe $(TESTS_OUTDIR)/run-tests.exe
	cp $(SRCDIR)/tools/run-tests/*.txt $(SRCDIR)/tools/run-tests/run-on-windows.bat $(TESTS_OUTDIR)/
.PHONY: tests

clean-tests-runtestsexe:
	rm -rf $(TESTS_OUTDIR)/run-tests.exe $(TESTS_OUTDIR)/*.txt $(TESTS_OUTDIR)/run-on-windows.bat
.PHONY: clean-tests-runtestsexe
clean-tests: clean-tests-runtestsexe

$(OUTDIR)/wine-mono-$(MSI_VERSION)-tests.zip: tests
	rm -f wine-mono-$(MSI_VERSION)-tests.zip
	do_zip () { if which 7z; then 7z a "$$@"; elif which zip; then zip -r "$$@"; else exit 1; fi; }; cd $(OUTDIR); do_zip wine-mono-$(MSI_VERSION)-tests.zip tests/

tests-zip: $(OUTDIR)/wine-mono-$(MSI_VERSION)-tests.zip

clean-tests-zip:
	rm -rf $(OUTDIR)/wine-mono-$(MSI_VERSION)-tests.zip
.PHONY: clean-tests-zip
clean: clean-tests-zip

$(BUILDDIR)/resx2srid.exe: $(SRCDIR)/tools/resx2srid/resx2srid.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc $(SRCDIR)/tools/resx2srid/resx2srid.cs -out:$(BUILDDIR)/resx2srid.exe

clean-build-resx2srid:
	rm -rf $(BUILDDIR)/resx2srid.exe
.PHONY: clean-build-resx2srid
clean-build: clean-build-resx2srid

clean-tests:
	-rmdir $(TESTS_OUTDIR)
.PHONY: clean-tests
clean: clean-tests

include tools/tests/tests.make

test: tests image
	WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix $(WINE) reg add 'HKCU\Software\Wine\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f
	WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix $(MAKE) dev-setup
	WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix $(WINE) explorer /desktop=wine-mono-test '$(shell $(WINE) winepath -w $(TESTS_OUTDIR)/run-tests.exe)' -skip-list:'$(shell $(WINE) winepath -w $(SRCDIR)/tools/run-tests/skip-always.txt)' -skip-list:'$(shell $(WINE) winepath -w $(SRCDIR)/tools/run-tests/windows-failing.txt)' -fail-list:'$(shell $(WINE) winepath -w $(SRCDIR)/tools/run-tests/wine-failing.txt)' -pass-list:'$(shell $(WINE) winepath -w $(SRCDIR)/tools/run-tests/wine-passing.txt)'

clean-build-test-prefix:
	-WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix wineserver -k
	rm -rf $(BUILDDIR)/.wine-test-prefix
.PHONY: clean-build-test-prefix
clean-build: clean-build-test-prefix

$(BUILDDIR)/genfilehashes.exe: $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/genfilehashes/genfilehashes.cs
	$(MONO_ENV) mcs $(SRCDIR)/tools/genfilehashes/genfilehashes.cs -out:$@ -r:Mono.Posix

clean-genfilehashes:
	rm -rf $(BUILDDIR)/genfilehashes.exe
.PHONY: clean-genfilehashes
clean-build: clean-genfilehashes

support-fakedllsinf: $(SRCDIR)/dotnetfakedlls.inf
	mkdir -p $(IMAGEDIR)/support/
	cp $(SRCDIR)/dotnetfakedlls.inf $(IMAGEDIR)/support/
.PHONY: support-fakedllsinf
imagedir-targets: support-fakedllsinf
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/dotnetfakedlls.inf

$(BUILDDIR)/.imagedir-built: $(IMAGEDIR_BUILD_TARGETS)
	rm -rf "$(IMAGEDIR)"
	+$(MAKE) imagedir-targets
	touch "$@"
clean-imagedir-built:
	rm -f $(BUILDDIR)/.imagedir-built
.PHONY: clean-imagedir-built
clean-build: clean-imagedir-built

image: $(BUILDDIR)/.imagedir-built
.PHONY: image

clean-image:
	rm -rf "$(IMAGEDIR)"
.PHONY: clean-image
clean: clean-image

$(BUILDDIR)/.runtimemsitables-built: $(BUILDDIR)/.imagedir-built $(SRCDIR)/msi-tables/runtime/*.idt $(SRCDIR)/tools/build-msi-tables.sh $(BUILDDIR)/genfilehashes.exe $(SRCDIR)/GNUmakefile
	$(MONO_ENV) WHICHMSI=runtime MSI_VERSION=$(MSI_VERSION) CABFILENAME=$(BUILDDIR_ABS)/image.cab TABLEDIR=$(BUILDDIR_ABS)/msi-tables/runtime TABLESRCDIR=$(SRCDIR_ABS)/msi-tables/runtime IMAGEDIR=$(IMAGEDIR_ABS) ROOTDIR=MONODIR CABINET='#image.cab' GENFILEHASHES=$(BUILDDIR_ABS)/genfilehashes.exe WINE=$(WINE) sh $(SRCDIR)/tools/build-msi-tables.sh
	touch $@

$(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi: $(BUILDDIR)/.runtimemsitables-built
	rm -f "$@"
	$(WINE) winemsibuilder -i '$(shell $(WINE) winepath -w $@)' $(BUILDDIR)/msi-tables/runtime/*.idt
	$(WINE) winemsibuilder -a '$(shell $(WINE) winepath -w $@)' image.cab '$(shell $(WINE) winepath -w $(BUILDDIR)/image.cab)'

clean-image-cab:
	rm -f $(BUILDDIR)/image.cab
	rm -f $(BUILDDIR)/.runtimemsitables-built
.PHONY: clean-image-cab
clean-build: clean-image-cab

msi: $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi
.PHONY: msi

clean-msi:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi
.PHONY: clean-msi
clean: clean-msi

$(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/.imagedir-built
	cd $(IMAGEDIR)/..; tar cf $(OUTDIR_ABS)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX) --transform 's:^$(notdir $(IMAGEDIR_ABS)):wine-mono-$(MSI_VERSION):g' '--use-compress-program=$(COMPRESSOR)' $(notdir $(IMAGEDIR_ABS))

bin: $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX)
.PHONY: bin

targz: bin
.PHONY: targz

clean-targz:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX)
.PHONY: clean-targz
clean: clean-targz

$(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/mono-unix/.built $(FETCH_LLVM_MINGW)/.dir
	$(SRCDIR)/tools/archive.sh `git describe` $(OUTDIR_ABS) wine-mono-$(MSI_VERSION)-src $(FETCH_LLVM_MINGW_DIRECTORY)
	rm -f $@
	$(COMPRESSOR) $(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar

source: $(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar.$(COMPRESSED_SUFFIX)
.PHONY: source

clean-source:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar.$(COMPRESSED_SUFFIX)
.PHONY: clean-source
clean: clean-source

print-env:
	@echo $(MONO_ENV)
