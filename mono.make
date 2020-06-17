HAVE_MONOLITE=$(shell test -e $(SRCDIR)/monolite/mcs.exe && echo 1 || echo 0)

MONO_MAKEFILES=$(shell cd $(SRCDIR); find mono -name Makefile.am)

MONO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono)
MONO_BTLS_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/mono/btls $(SRCDIR)/mono/external/boringssl)
MONO_MONO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/mono)
MONO_LIBNATIVE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/mono/native)

$(SRCDIR)/mono/configure: $(SRCDIR)/mono/autogen.sh $(SRCDIR)/mono/configure.ac $(MONO_MAKEFILES)
	cd $(SRCDIR)/mono; NOCONFIGURE=yes ./autogen.sh

define MINGW_TEMPLATE +=

# libmono dll's
$$(BUILDDIR)/mono-$(1)/Makefile: $$(SRCDIR)/mono/configure $$(SRCDIR)/mono.make $$(BUILDDIR)/.dir $$(MINGW_DEPS)
	mkdir -p $$(@D)
	cd $$(BUILDDIR)/mono-$(1); $$(MINGW_ENV) CPPFLAGS="-gdwarf-2 -gstrict-dwarf" $$(SRCDIR_ABS)/mono/configure --prefix="$$(BUILDDIR_ABS)/build-cross-$(1)-install" --build=$$(shell $$(SRCDIR)/mono/config.guess) --target=$$(MINGW_$(1)) --host=$$(MINGW_$(1)) --with-tls=none --disable-mcs-build --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG=false mono_cv_clang=no --disable-boehm
	sed -e 's/-lgcc_s//' -i $$(BUILDDIR)/mono-$(1)/libtool

$$(BUILDDIR)/mono-$(1)/.built: $$(BUILDDIR)/mono-$(1)/Makefile $$(MONO_MONO_SRCS) $$(MINGW_DEPS)
	+WINEPREFIX=/dev/null $$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/mono-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/mono-$(1)/.built

$$(BUILDDIR)/mono-$(1)/support/.built: $$(BUILDDIR)/mono-$(1)/.built $$(MINGW_DEPS)
	+WINEPREFIX=/dev/null $$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/mono-$(1)/support
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/mono-$(1)/support/.built

libmono-2.0-$(1).dll: $$(BUILDDIR)/mono-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/bin"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/mono-$(1)/mono/mini/.libs/libmonosgen-2.0.dll" "$$(IMAGEDIR)/bin/libmono-2.0-$(1).dll"

.PHONY: libmono-2.0-$(1).dll
imagedir-targets: libmono-2.0-$(1).dll

MonoPosixHelper-$(1).dll: $$(BUILDDIR)/mono-$(1)/support/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/mono-$(1)/support/.libs/libMonoPosixHelper.dll" "$$(IMAGEDIR)/lib/MonoPosixHelper-$(1).dll"
.PHONY: MonoPosixHelper-$(1).dll
imagedir-targets: MonoPosixHelper-$(1).dll

clean-build-mono-$(1):
	rm -rf $$(BUILDDIR)/mono-$(1)
.PHONY: clean-build-mono-$(1)
clean-build: clean-build-mono-$(1)

# BTLS
$$(BUILDDIR)/btls-$(1)/Makefile: $$(SRCDIR)/mono/mono/btls/CMakeLists.txt $$(SRCDIR)/mono.make $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	# wincrypt.h interferes with boringssl definitions, so we prevent its inclusion
	cd $$(@D); $$(MINGW_ENV) cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_C_FLAGS='-D__WINCRYPT_H__ -D_WIN32_WINNT=0x0600 -static-libgcc' -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DOPENSSL_NO_ASM=1 -DBTLS_ROOT="$$(SRCDIR_ABS)/mono/external/boringssl" -DBUILD_SHARED_LIBS=1 $$(SRCDIR_ABS)/mono/mono/btls

$$(BUILDDIR)/btls-$(1)/.built: $$(BUILDDIR)/btls-$(1)/Makefile $$(MONO_BTLS_SRCS) $$(MINGW_DEPS)
	+WINEPREFIX=/dev/null $$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/btls-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/btls-$(1)/.built

libmono-btls-$(1).dll: $$(BUILDDIR)/btls-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/btls-$(1)/libmono-btls-shared.dll" "$$(IMAGEDIR)/lib/libmono-btls-$(1).dll"
.PHONY: libmono-btls-$(1).dll
imagedir-targets: libmono-btls-$(1).dll

clean-build-btls-$(1):
	rm -rf $$(BUILDDIR)/btls-$(1)
.PHONY: clean-build-btls-$(1)
clean-build: clean-build-btls-$(1)

# mono libtest.dll
$$(TESTS_OUTDIR)/tests-$(1)/libtest.dll: $$(BUILDDIR)/mono-$(1)/.built $$(MINGW_DEPS)
	+WINEPREFIX=/dev/null $$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/mono-$(1)/mono/tests libtest.la
	mkdir -p $$(@D)
	cp $$(BUILDDIR)/mono-$(1)/mono/tests/.libs/libtest-0.dll $$@
tests: $$(TESTS_OUTDIR)/tests-$(1)/libtest.dll

clean-tests-$(1):
	rm -rf $$(TESTS_OUTDIR)/tests-$(1)
.PHONY: clean-tests-$(1)
clean-tests: clean-tests-$(1)

tests-runtime-$(1): $$(BUILDDIR)/mono-unix/mono/mini/.built-tests $$(BUILDDIR)/mono-unix/mono/tests/.built $$(BUILDDIR)/set32only.exe
	mkdir -p $$(TESTS_OUTDIR)/tests-$(1)
	cp $$(BUILDDIR)/mono-unix/mono/tests/*.exe $$(BUILDDIR)/mono-unix/mono/tests/*.dll $$(BUILDDIR)/mono-unix/mono/mini/*.exe $$(TESTS_OUTDIR)/tests-$(1)
	mkdir -p $$(TESTS_OUTDIR)/tests-$(1)/assembly-load-dir1
	# exclude libsimplename.dll because it's undefined which one we'll get on a case-insensitive filesystem
	cp $$(BUILDDIR)/mono-unix/mono/tests/assembly-load-dir1/Lib*.dll $$(TESTS_OUTDIR)/tests-$(1)/assembly-load-dir1
	mkdir -p $$(TESTS_OUTDIR)/tests-$(1)/assembly-load-dir2
	cp $$(BUILDDIR)/mono-unix/mono/tests/assembly-load-dir2/*.dll $$(TESTS_OUTDIR)/tests-$(1)/assembly-load-dir2
ifeq ($(1),x86)
	cp $$(BUILDDIR)/mono-unix/builtin-types-32.exe $$(TESTS_OUTDIR)/tests-$(1)/builtin-types.exe
	cd $$(TESTS_OUTDIR)/tests-$(1); $$(WINE) $$(BUILDDIR_ABS)/set32only.exe *.exe
endif

tests: tests-runtime-$(1)

ifeq ($(1),x86)
tests-runtime-$(1): $$(BUILDDIR)/mono-unix/builtin-types-32.exe
endif

endef

# mono native/classlib build
$(BUILDDIR)/mono-unix/Makefile: $(SRCDIR)/mono/configure $(SRCDIR)/mono.make $(BUILDDIR)/.dir
	mkdir -p $(@D)
	cd $(@D) && $(SRCDIR_ABS)/mono/configure --prefix="$(BUILDDIR_ABS)/mono-unix-install" --with-mcs-docs=no --disable-system-aot --without-compiler-server

$(BUILDDIR)/mono-unix/mono/lib/libSystem.Native.so: $(BUILDDIR)/mono-unix/Makefile $(MONO_LIBNATIVE_SRCS)
	mkdir -p $(@D)
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix/mono/native
	cp $(BUILDDIR)/mono-unix/mono/native/.libs/libmono-native.so $@

ifeq ($(HAVE_MONOLITE),1)
MONOLITE_PATH=$(SRCDIR_ABS)/monolite
MONOLITE_OPTS="EXTERNAL_RUNTIME=MONO_PATH=$(MONOLITE_PATH) $(BUILDDIR_ABS)/mono-unix/mono/mini/mono-sgen" "EXTERNAL_MCS=\$$(EXTERNAL_RUNTIME) $(MONOLITE_PATH)/mcs.exe"
else
MONOLITE_OPTS=
endif

$(BUILDDIR)/mono-unix/.built: $(BUILDDIR)/mono-unix/Makefile $(BUILDDIR)/mono-unix/mono/lib/libSystem.Native.so $(MONO_SRCS)
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix $(MONOLITE_OPTS)
	touch $@

$(BUILDDIR)/mono-unix/.built-win32: $(BUILDDIR)/mono-unix/.built
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix $(MONOLITE_OPTS) HOST_PLATFORM=win32
	touch $@

mscorlib.dll: $(BUILDDIR)/mono-unix/Makefile
	+$(MAKE) -C $(SRCDIR_ABS)/mono/mcs/class/corlib $(MONOLITE_OPTS) HOST_PLATFORM=win32
	cp $(SRCDIR)/mono/mcs/class/lib/net_4_x-win32/mscorlib.dll $(IMAGEDIR)/lib/mono/4.5
.PHONY: mscorlib.dll

%.dll: $(SRCDIR)/mono/mcs/class/%/Makefile $(BUILDDIR)/mono-unix/Makefile
	+$(MAKE) -C $(SRCDIR_ABS)/mono/mcs/class/$(basename $@) $(MONOLITE_OPTS) HOST_PLATFORM=win32
	$(MONO_ENV) gacutil -i $(SRCDIR)/mono/mcs/class/lib/net_4_x-win32/$@ -root $(IMAGEDIR)/lib
.PHONY: mscorlib.dll

$(BUILDDIR)/mono-unix/.installed: $(BUILDDIR)/mono-unix/.built $(BUILDDIR)/mono-unix/.built-win32
	rm -rf $(BUILDDIR)/mono-unix-install $(BUILDDIR)/mono-win32-install
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix $(MONOLIST_OPTS) HOST_PLATFORM=win32 install
	mv $(BUILDDIR)/mono-unix-install $(BUILDDIR)/mono-win32-install
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix $(MONOLIST_OPTS) install
ifneq (1,$(ENABLE_DEBUG_SYMBOLS))
	for f in `find $(BUILDDIR)/mono-win32-install|grep -E '\.(mdb|pdb)$$'`; do rm "$$f"; done
endif
ifeq (1,$(ENABLE_DOTNET_CORE_WINFORMS))
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/Accessibility
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/System.Windows.Forms
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/System.Windows.Forms.DataVisualization
endif
ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/System.Xaml
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/WindowsBase
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/System.Windows.Input.Manipulations
endif
	touch $@
IMAGEDIR_BUILD_TARGETS += $(BUILDDIR)/mono-unix/.installed

clean-build-mono-unix:
	rm -rf $(BUILDDIR)/mono-unix $(BUILDDIR)/mono-unix-install $(BUILDDIR)/mono-win32-install
.PHONY: clean-build-mono-unix
clean-build: clean-build-mono-unix

mono-image: $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(IMAGEDIR)/lib
	$(CP_R) $(BUILDDIR)/mono-win32-install/etc $(IMAGEDIR)
	$(CP_R) $(BUILDDIR)/mono-win32-install/lib/mono $(IMAGEDIR)/lib
.PHONY: mono-image
imagedir-targets: mono-image

$(BUILDDIR)/mono-unix/.built-clr-tests: $(BUILDDIR)/mono-unix/.built
	+$(MAKE) -C $(SRCDIR_ABS)/mono/mcs/class test
	touch $@

$(BUILDDIR)/nunitlite.dll: $(BUILDDIR)/mono-unix/.installed
	cd $(SRCDIR)/mono/mcs/tools/nunit-lite/NUnitLite/ && $(MONO_ENV) csc /nostdlib /r:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.0-api/mscorlib.dll /r:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.0-api/System.dll /lib:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.0-api /codepage:65001 /deterministic /target:library /define:"__MOBILE__;TRACE;DEBUG;NET_4_0;CLR_4_0,NUNITLITE" /warn:4 -d:NET_4_0 -d:MONO -d:WIN_PLATFORM -nowarn:1699 /debug:portable -optimize /features:peverify-compat /langversion:latest /keyfile:$(SRCDIR_ABS)/mono/mcs/class/mono.snk  -target:library -out:$(BUILDDIR_ABS)/nunitlite.dll @nunitlite.dll.sources

clean-build-nunitlite:
	rm -rf $(BUILDDIR)/nunitlite.dll $(BUILDDIR)/nunitlite.pdb
.PHONY: clean-build-nunitlite
clean-build: clean-build-nunitlite

$(BUILDDIR)/mono-unix/mono/tests/.built: $(BUILDDIR)/mono-unix/.built
	+$(MAKE) -C $(@D) test-local
	touch $@

$(BUILDDIR)/mono-unix/mono/mini/.built-tests: $(BUILDDIR)/mono-unix/.built
	+$(MAKE) -C $(@D) test-local
	touch $@

$(BUILDDIR)/mono-unix/builtin-types-32.exe: $(SRCDIR)/mono/mono/mini/builtin-types.cs $(BUILDDIR)/mono-unix/mono/mini/.built-tests $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) mcs -out:$@ -unsafe -define:ARCH_32 $< -r:$(BUILDDIR)/mono-unix/mono/mini/TestDriver.dll

tests-clr: $(BUILDDIR)/mono-unix/.built-clr-tests $(BUILDDIR)/nunitlite.dll $(BUILDDIR)/set32only.exe
	mkdir -p $(TESTS_OUTDIR)/tests-clr
	cp $(SRCDIR)/mono/mcs/class/lib/net_4_x/tests/*_test.dll $(SRCDIR)/mono/mcs/class/lib/net_4_x/nunit* $(TESTS_OUTDIR)/tests-clr
	cp $(BUILDDIR)/nunitlite.* $(TESTS_OUTDIR)/tests-clr
	mkdir -p $(TESTS_OUTDIR)/tests-clr/Test/System.Drawing
	cp -r $(SRCDIR)/mono/mcs/class/System.Drawing/Test/System.Drawing/bitmaps $(TESTS_OUTDIR)/tests-clr/Test/System.Drawing
	cp -r $(SRCDIR)/mono/mcs/class/System.Windows.Forms/Test/resources $(TESTS_OUTDIR)/tests-clr/Test
	cp $(TESTS_OUTDIR)/tests-clr/nunit-lite-console.exe $(TESTS_OUTDIR)/tests-clr/nunit-lite-console32.exe
	cd $(TESTS_OUTDIR)/tests-clr; $(WINE) $(BUILDDIR_ABS)/set32only.exe nunit-lite-console32.exe
	cd $(TESTS_OUTDIR)/tests-clr; for f in *_test.dll; do $(MONO_ENV) mono nunit-lite-console.exe $$f -explore:$${f}.testlist >/dev/null || rm $$f; done
.PHONY: tests-clr
tests: tests-clr

clean-tests-clr:
	rm -rf $(TESTS_OUTDIR)/tests-clr
.PHONY: clean-tests-clr
clean-tests: clean-tests-clr

