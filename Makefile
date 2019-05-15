
# configuration
SRCDIR=$(dir $(MAKEFILE_LIST))
BUILDDIR=$(SRCDIR)/build
IMAGEDIR=$(SRCDIR)/image
OUTDIR=$(SRCDIR)

MINGW_x86=i686-w64-mingw32
MINGW_x86_64=x86_64-w64-mingw32

WINE=wine

ENABLE_DOTNET_CORE_WINFORMS=1

MSI_VERSION=4.8.99

# variables
SRCDIR_ABS=$(shell cd $(SRCDIR); pwd)
BUILDDIR_ABS=$(shell cd $(BUILDDIR); pwd)
IMAGEDIR_ABS=$(shell cd $(IMAGEDIR); pwd)
OUTDIR_ABS=$(shell cd $(OUTDIR); pwd)

HAVE_MONOLITE=$(shell test -e $(SRCDIR)/monolite/mcs.exe && echo 1 || echo 0)

MONO_MAKEFILES=$(shell cd $(SRCDIR); find mono -name Makefile.am)

MONO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono)
MONO_MONO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/mono $(SRCDIR)/mono/libgc)
MONO_LIBNATIVE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/native)
MONO_BASIC_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono-basic)
FNA_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA)
FNA_NETSTUB_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA.NetStub)
SDL2_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL2)
FAUDIO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FAudio)
SDLIMAGE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL_image_compact)
THEORAFILE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/Theorafile)
MOJOSHADER_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/MojoShader)
WINFORMS_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/winforms)

MONO_BIN_PATH=$(BUILDDIR_ABS)/mono-unix-install/bin
MONO_LD_PATH=$(BUILDDIR_ABS)/mono-unix-install/lib
MONO_GAC_PREFIX=$(BUILDDIR_ABS)/mono-unix-install
MONO_CFG_DIR=$(BUILDDIR_ABS)/mono-unix-install/etc
MONO_ENV=PATH="$(MONO_BIN_PATH):$$PATH" LD_LIBRARY_PATH="$(MONO_LD_PATH):$$LD_LIBRARY_PATH" MONO_GAC_PREFIX="$(MONO_GAC_PREFIX)" MONO_CFG_DIR="$(MONO_CFG_DIR)"

CP_R=python $(SRCDIR_ABS)/tools/copy_recursive.py

all: image targz msi
.PHONY: all clean imagedir-targets tests

define HELP_TEXT =
The following targets are defined:
	image:        Build the image/ directory, for direct use as a runtime by Wine.
	msi:	      Build wine-mono-$(MSI_VERSION).msi
	targz:	      Build wine-mono-bin-$(MSI_VERSION).tar.gz
	tests:        Build the mono tests.
	System.dll:   Build a single dll and add it to the image/ directory.
endef

define newline =


endef

help:
	@echo -e '$(subst $(newline),\n,$(HELP_TEXT))'

$(SRCDIR)/mono/configure: $(SRCDIR)/mono/autogen.sh $(SRCDIR)/mono/configure.ac $(SRCDIR)/mono/libgc/autogen.sh $(SRCDIR)/mono/libgc/configure.ac $(MONO_MAKEFILES)
	cd $(SRCDIR)/mono; NOCONFIGURE=yes ./autogen.sh

$(BUILDDIR)/.dir:
	mkdir -p $(BUILDDIR)
	touch $(BUILDDIR)/.dir

clean-build:
	rm -f $(BUILDDIR)/.dir
	rmdir $(BUILDDIR)
clean: clean-build
.PHONY: clean-build

# mingw targets
define MINGW_TEMPLATE =
# libmono dll's
$$(BUILDDIR)/mono-$(1)/Makefile: $$(SRCDIR)/mono/configure $$(BUILDDIR)/.dir
	mkdir -p $$(@D)
	cd $$(BUILDDIR)/mono-$(1); CPPFLAGS="-gdwarf-2 -gstrict-dwarf" $$(SRCDIR_ABS)/mono/configure --prefix="$$(BUILDDIR_ABS)/build-cross-$(1)-install" --build=$$(shell $$(SRCDIR)/mono/config.guess) --target=$$(MINGW_$(1)) --host=$$(MINGW_$(1)) --with-tls=none --disable-mcs-build --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG=false mono_cv_clang=no
	sed -e 's/-lgcc_s//' -i $$(BUILDDIR)/mono-$(1)/libtool

$$(BUILDDIR)/mono-$(1)/.built: $$(BUILDDIR)/mono-$(1)/Makefile $$(MONO_MONO_SRCS)
	+$$(MAKE) -C $$(BUILDDIR)/mono-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/mono-$(1)/.built

$$(BUILDDIR)/mono-$(1)/support/.built: $$(BUILDDIR)/mono-$(1)/.built
	+$$(MAKE) -C $$(BUILDDIR)/mono-$(1)/support
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/mono-$(1)/support/.built

libmono-2.0-$(1).dll: $$(BUILDDIR)/mono-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/bin"
	cp "$$(BUILDDIR)/mono-$(1)/mono/mini/.libs/libmonosgen-2.0.dll" "$$(IMAGEDIR)/bin/libmono-2.0-$(1).dll"
.PHONY: libmono-2.0-$(1).dll
imagedir-targets: libmono-2.0-$(1).dll

MonoPosixHelper-$(1).dll: $$(BUILDDIR)/mono-$(1)/support/.built
	mkdir -p "$$(IMAGEDIR)/bin"
	cp "$$(BUILDDIR)/mono-$(1)/support/.libs/libMonoPosixHelper.dll" "$$(IMAGEDIR)/bin/MonoPosixHelper-$(1).dll"
.PHONY: MonoPosixHelper-$(1).dll
imagedir-targets: MonoPosixHelper-$(1).dll

clean-build-mono-$(1):
	rm -rf $$(BUILDDIR)/mono-$(1)
.PHONY: clean-build-mono-$(1)
clean-build: clean-build-mono-$(1)

# mono libtest.dll
$$(OUTDIR)/tests-$(1)/libtest.dll: $$(BUILDDIR)/mono-$(1)/.built
	+$$(MAKE) -C $$(BUILDDIR)/mono-$(1)/mono/tests libtest.la
	mkdir -p $$(@D)
	cp $$(BUILDDIR)/mono-$(1)/mono/tests/.libs/libtest-0.dll $$@
tests: $$(OUTDIR)/tests-$(1)/libtest.dll

clean-tests-$(1):
	rm -rf $$(OUTDIR)/tests-$(1)
.PHONY: clean-tests-$(1)
clean: clean-tests-$(1)

tests-runtime-$(1): $$(BUILDDIR)/mono-unix/mono/tests/.built
	mkdir -p $$(OUTDIR)/tests-$(1)
	cp $$(BUILDDIR)/mono-unix/mono/tests/*.exe $$(BUILDDIR)/mono-unix/mono/tests/*.dll $$(OUTDIR)/tests-$(1)
tests: tests-runtime-$(1)

# FNA native deps
# SDL2
$$(BUILDDIR)/SDL2-$(1)/Makefile: $$(SRCDIR)/SDL2/configure $$(SRCDIR)/mono/configure
	mkdir -p $$(@D)
	cd $$(BUILDDIR)/SDL2-$(1); CC="$$(MINGW_$(1))-gcc -static-libgcc" CXX="$$(MINGW_$(1))-g++ -static-libgcc -static-libstdc++" $$(SRCDIR_ABS)/SDL2/configure --build=$$(shell $$(SRCDIR)/mono/config.guess) --target=$$(MINGW_$(1)) --host=$$(MINGW_$(1)) PKG_CONFIG=false

$$(BUILDDIR)/SDL2-$(1)/.built: $$(BUILDDIR)/SDL2-$(1)/Makefile $$(SDL2_SRCS)
	+$$(MAKE) -C $$(BUILDDIR)/SDL2-$(1) TARGET=libSDL2-$(1).la
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/SDL2-$(1)/.built

SDL2-$(1).dll: $$(BUILDDIR)/SDL2-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	cp "$$(BUILDDIR)/SDL2-$(1)/build/.libs/SDL2-$(1).dll" "$$(IMAGEDIR)/lib/SDL2-$(1).dll"
.PHONY: SDL2-$(1).dll
imagedir-targets: SDL2-$(1).dll

clean-build-SDL2-$(1):
	rm -rf $$(BUILDDIR)/SDL2-$(1)
.PHONY: clean-build-SDL2-$(1)
clean-build: clean-build-SDL2-$(1)

# FAudio
$$(BUILDDIR)/FAudio-$(1)/Makefile: $$(SRCDIR)/FNA/lib/FAudio/CMakeLists.txt $$(BUILDDIR)/SDL2-$(1)/.built
	mkdir -p $$(@D)
	cd $$(@D); cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DSDL2_INCLUDE_DIRS="$$(BUILDDIR_ABS)/SDL2-$(1)/include;$$(SRCDIR_ABS)/SDL2/include" -DSDL2_LIBRARIES="$$(BUILDDIR_ABS)/SDL2-$(1)/build/.libs/libSDL2-$(1).dll.a" $$(SRCDIR_ABS)/FNA/lib/FAudio

$$(BUILDDIR)/FAudio-$(1)/.built: $$(BUILDDIR)/FAudio-$(1)/Makefile $$(FAUDIO_SRCS)
	+$$(MAKE) -C $$(BUILDDIR)/FAudio-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/FAudio-$(1)/.built

FAudio-$(1).dll: $$(BUILDDIR)/FAudio-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	cp "$$(BUILDDIR)/FAudio-$(1)/FAudio.dll" "$$(IMAGEDIR)/lib/FAudio-$(1).dll"
.PHONY: FAudio-$(1).dll
imagedir-targets: FAudio-$(1).dll

clean-build-FAudio-$(1):
	rm -rf $$(BUILDDIR)/FAudio-$(1)
.PHONY: clean-build-FAudio-$(1)
clean-build: clean-build-FAudio-$(1)

# SDL2_image
$$(BUILDDIR)/SDL_image_compact-$(1)/.built: $$(BUILDDIR)/SDL2-$(1)/.built $$(SDLIMAGE_SRCS)
	mkdir -p $$(BUILDDIR)/SDL_image_compact-$(1)
	+$$(MAKE) -C $$(BUILDDIR_ABS)/SDL_image_compact-$(1) "CC=$$(MINGW_$(1))-gcc" SDL_LDFLAGS="$$(BUILDDIR_ABS)/SDL2-$(1)/build/.libs/libSDL2-$(1).dll.a" SDL_CFLAGS="-I$$(BUILDDIR_ABS)/SDL2-$(1)/include -I$$(SRCDIR_ABS)/SDL2/include" WICBUILD=1 -f $$(SRCDIR_ABS)/SDL_image_compact/Makefile
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/SDL_image_compact-$(1)/.built

SDL2_image-$(1).dll: $$(BUILDDIR)/SDL_image_compact-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	cp "$$(BUILDDIR)/SDL_image_compact-$(1)/SDL2_image.dll" "$$(IMAGEDIR)/lib/SDL2_image-$(1).dll"
.PHONY: SDL2_image-$(1).dll
imagedir-targets: SDL2_image-$(1).dll

clean-build-SDL_image_compact-$(1):
	rm -rf $$(BUILDDIR)/SDL_image_compact-$(1)
.PHONY: clean-build-SDL_image_compact-$(1)
clean-build: clean-build-SDL_image_compact-$(1)

# libtheorafile
$$(BUILDDIR)/Theorafile-$(1)/.built: $$(THEORAFILE_SRCS)
	mkdir -p $$(BUILDDIR)/Theorafile-$(1)
	+$$(MAKE) -C $$(BUILDDIR_ABS)/Theorafile-$(1) "CC=$$(MINGW_$(1))-gcc" -f $$(SRCDIR_ABS)/FNA/lib/Theorafile/Makefile
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/Theorafile-$(1)/.built

libtheorafile-$(1).dll: $$(BUILDDIR)/Theorafile-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	cp "$$(BUILDDIR)/Theorafile-$(1)/libtheorafile.dll" "$$(IMAGEDIR)/lib/libtheorafile-$(1).dll"
.PHONY: libtheorafile-$(1).dll
imagedir-targets: libtheorafile-$(1).dll

clean-build-Theorafile-$(1):
	rm -rf $$(BUILDDIR)/Theorafile-$(1)
.PHONY: clean-build-Theorafile-$(1)
clean-build: clean-build-Theorafile-$(1)

# libmojoshader
$$(BUILDDIR)/MojoShader-$(1)/Makefile: $$(SRCDIR)/FNA/lib/MojoShader/CMakeLists.txt
	mkdir -p $$(@D)
	cd $$(@D); cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DBUILD_SHARED=ON -DPROFILE_D3D=OFF -DPROFILE_BYTECODE=OFF -DPROFILE_ARB1=OFF -DPROFILE_ARB1_NV=OFF -DPROFILE_METAL=OFF -DCOMPILER_SUPPORT=OFF -DFLIP_VIEWPORT=ON -DDEPTH_CLIPPING=ON -DXNA4_VERTEXTEXTURE=ON $$(SRCDIR_ABS)/FNA/lib/MojoShader

$$(BUILDDIR)/MojoShader-$(1)/.built: $$(BUILDDIR)/MojoShader-$(1)/Makefile $$(MOJOSHADER_SRCS)
	+$$(MAKE) -C $$(BUILDDIR)/MojoShader-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/MojoShader-$(1)/.built

libmojoshader-$(1).dll: $$(BUILDDIR)/MojoShader-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	cp "$$(BUILDDIR)/MojoShader-$(1)/libmojoshader.dll" "$$(IMAGEDIR)/lib/libmojoshader-$(1).dll"
.PHONY: libmojoshader-$(1).dll
imagedir-targets: libmojoshader-$(1).dll

clean-build-MojoShader-$(1):
	rm -rf $$(BUILDDIR)/MojoShader-$(1)
.PHONY: clean-build-MojoShader-$(1)
clean-build: clean-build-MojoShader-$(1)
endef

$(eval $(call MINGW_TEMPLATE,x86))
$(eval $(call MINGW_TEMPLATE,x86_64))

# mono native/classlib build
$(BUILDDIR)/mono-unix/Makefile: $(SRCDIR)/mono/configure
	mkdir -p $(@D)
	cd $(@D) && $(SRCDIR_ABS)/mono/configure --prefix="$(BUILDDIR_ABS)/mono-unix-install" --with-mcs-docs=no --disable-system-aot

$(BUILDDIR)/mono-unix/mono/lib/libSystem.Native.so: $(BUILDDIR)/mono-unix/Makefile $(MONO_LIBNATIVE_SRCS)
	mkdir -p $(@D)
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix/mono/native
	cp $(BUILDDIR)/mono-unix/mono/native/.libs/libmono-native.so $@

ifeq ($(HAVE_MONOLITE),1)
	MONOLITE_PATH=$(SRCDIR_ABS)/monolite
	MONOLITE_OPTS="EXTERNAL_RUNTIME=MONO_PATH=$(MONOLITE_PATH) $(BUILDDIR_ABS)/mono-unix/mono/mini/mono-sgen" "EXTERNAL_MCS=\$(EXTERNAL_RUNTIME) $(MONOLITE_PATH)/mcs.exe"
else
	MONOLITE_OPTS=
endif

$(BUILDDIR)/mono-unix/.built: $(BUILDDIR)/mono-unix/Makefile $(BUILDDIR)/mono-unix/mono/lib/libSystem.Native.so
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
	for f in `find $(BUILDDIR)/mono-win32-install|grep -E '\.(mdb|pdb)$$'`; do rm "$$f"; done
ifeq (1,$(ENABLE_DOTNET_CORE_WINFORMS))
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/Accessibility
	rm -rf $(BUILDDIR)/mono-win32-install/lib/mono/gac/System.Windows.Forms
endif
	touch $@
IMAGEDIR_BUILD_TARGETS += $(BUILDDIR)/mono-unix/.installed

mono-image: $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(IMAGEDIR)/lib
	$(CP_R) $(BUILDDIR)/mono-win32-install/etc $(IMAGEDIR)
	$(CP_R) $(BUILDDIR)/mono-win32-install/lib/mono $(IMAGEDIR)/lib
.PHONY: mono-image
imagedir-targets: mono-image

$(BUILDDIR)/mono-unix/.built-clr-tests: $(BUILDDIR)/mono-unix/.built
	+$(MAKE) -C $(SRCDIR_ABS)/mono/mcs/class test
	touch $@

tests-clr: $(BUILDDIR)/mono-unix/.built-clr-tests
	mkdir -p $(OUTDIR)/tests-clr
	cp $(SRCDIR)/mono/mcs/class/lib/net_4_x/tests/*_test.dll $(SRCDIR)/mono/mcs/class/lib/net_4_x/nunit* $(OUTDIR)/tests-clr
	mkdir -p $(OUTDIR)/tests-clr/Test/System.Drawing
	cp -r $(SRCDIR)/mono/mcs/class/System.Drawing/Test/System.Drawing/bitmaps $(OUTDIR)/tests-clr/Test/System.Drawing
	cp -r $(SRCDIR)/mono/mcs/class/System.Windows.Forms/Test/resources $(OUTDIR)/tests-clr/Test
.PHONY: tests-clr
tests: tests-clr

clean-tests-clr:
	rm -rf $(OUTDIR)/tests-clr
.PHONY: clean-tests-clr
clean: clean-tests-clr

$(BUILDDIR)/mono-unix/mono/tests/.built: $(BUILDDIR)/mono-unix/.built
	+$(MAKE) -C $(@D) test-local
	touch $@

clean-build-mono-unix:
	rm -rf $(BUILDDIR)/mono-unix $(BUILDDIR)/mono-unix-install $(BUILDDIR)/mono-win32-install
.PHONY: clean-build-mono-unix
clean-build: clean-build-mono-unix

$(SRCDIR)/mono-basic/build/config.make: $(SRCDIR)/mono-basic/configure $(BUILDDIR)/mono-unix/.installed
	cd $(SRCDIR)/mono-basic && $(MONO_ENV) ./configure --prefix=$(BUILDDIR_ABS)/mono-basic-install

$(SRCDIR)/mono-basic/.built: $(SRCDIR)/mono-basic/build/config.make $(MONO_BASIC_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/mono-basic PROFILE_VBNC_FLAGS=/sdkpath:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.5-api
	touch $@

$(SRCDIR)/mono-basic/.installed: $(SRCDIR)/mono-basic/.built
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

# dotnet core winforms
$(SRCDIR)/winforms/src/Accessibility/src/Accessibility.dll: $(BUILDDIR)/mono-unix/.installed $(WINFORMS_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)

$(SRCDIR)/winforms/.built: $(BUILDDIR)/mono-unix/.installed $(WINFORMS_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/winforms/src/System.Windows.Forms/src MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

ifeq (1,$(ENABLE_DOTNET_CORE_WINFORMS))
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/winforms/.built

Accessibility.dll: $(SRCDIR)/winforms/src/Accessibility/src/Accessibility.dll
	$(MONO_ENV) gacutil -i $(SRCDIR)/winforms/src/Accessibility/src/Accessibility.dll -root $(IMAGEDIR)/lib
.PHONY: Accessibility.dll

System.Windows.Forms.dll: $(SRCDIR)/winforms/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/winforms/src/Accessibility/src/Accessibility.dll -root $(IMAGEDIR)/lib
	$(MONO_ENV) gacutil -i $(SRCDIR)/winforms/src/System.Windows.Forms/src/System.Windows.Forms.dll -root $(IMAGEDIR)/lib
.PHONY: System.Windows.Forms.dll
imagedir-targets: System.Windows.Forms.dll
endif

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

# support file structure
# machine.config
$(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/CONFIG/machine.config)): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/etc/mono/2.0/machine.config $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/CONFIG/machine.config))

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/CONFIG/machine.config): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/etc/mono/4.0/machine.config $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/CONFIG/machine.config)

# security.config
$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/CONFIG/security.config): $(SRCDIR)/security.config
	mkdir -p $(@D)
	cp $(SRCDIR)/security.config $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/CONFIG/security.config)

# mscorlib.dll
$(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/mscorlib.dll)): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/lib/mono/2.0-api/mscorlib.dll $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/mscorlib.dll))

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/mscorlib.dll): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/lib/mono/4.0/mscorlib.dll $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/mscorlib.dll)

# csc.exe
$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/csc.exe): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	$(MONO_ENV) mcs $(SRCDIR)/tools/csc-wrapper/csc-wrapper.cs /d:VERSION20 -out:$@ -r:Mono.Posix
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/csc.exe)

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/csc.exe): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	$(MONO_ENV) mcs $(SRCDIR)/tools/csc-wrapper/csc-wrapper.cs /d:VERSION40 -out:$@ -r:Mono.Posix
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/csc.exe)

$(BUILDDIR)/.supportemptydirs: $(SRCDIR)/Makefile
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework/v3.0/wpf
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework/v3.0/"windows communication foundation"
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework64/v3.0/wpf
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework64/v3.0/"windows communication foundation"
	touch $@
IMAGE_SUPPORT_FILES += $(BUILDDIR)/.supportemptydirs

$(BUILDDIR)/genfilehashes.exe: $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/genfilehashes/genfilehashes.cs
	$(MONO_ENV) mcs $(SRCDIR)/tools/genfilehashes/genfilehashes.cs -out:$@ -r:Mono.Posix

clean-genfilehashes:
	rm -rf $(BUILDDIR)/genfilehashes.exe
.PHONY: clean-genfilehashes
clean-build: clean-genfilehashes

clean-image-support:
	rm -rf $(BUILDDIR)/image-support $(BUILDDIR)/.supportemptydirs
.PHONY: clean-image-support
clean-build: clean-image-support

$(BUILDDIR)/.supportmsitables-built: $(IMAGE_SUPPORT_FILES) $(SRCDIR)/msi-tables/support/*.idt $(SRCDIR)/tools/build-msi-tables.sh $(BUILDDIR)/genfilehashes.exe $(SRCDIR)/Makefile
	$(MONO_ENV) WHICHMSI=support MSI_VERSION=$(MSI_VERSION) CABFILENAME=$(BUILDDIR_ABS)/winemono-support.cab TABLEDIR=$(BUILDDIR_ABS)/msi-tables/support TABLESRCDIR=$(SRCDIR_ABS)/msi-tables/support IMAGEDIR=$(BUILDDIR_ABS)/image-support ROOTDIR=WindowsFolder CABINET=winemono-support.cab GENFILEHASHES=$(BUILDDIR_ABS)/genfilehashes.exe WINE=$(WINE) sh $(SRCDIR)/tools/build-msi-tables.sh
	touch $@

clean-msi-tables:
	rm -rf $(BUILDDIR)/msi-tables $(BUILDDIR)/.supportmsitables-built
.PHONY: clean-msi-tables
clean-build: clean-msi-tables

$(BUILDDIR)/winemono-support.msi: $(BUILDDIR)/.supportmsitables-built
	rm -f "$@"
	$(WINE) winemsibuilder -i '$(shell $(WINE) winepath -w $@)' $(BUILDDIR)/msi-tables/support/*.idt
IMAGEDIR_BUILD_TARGETS += $(BUILDDIR)/winemono-support.msi

clean-support-msi:
	rm -rf $(BUILDDIR)/winemono-support.msi
.PHONY: clean-support-msi
clean-build: clean-support-msi

winemono-support.msi winemono-support.cab: $(BUILDDIR)/winemono-support.msi
	mkdir -p $(IMAGEDIR)/support/
	cp $(BUILDDIR)/winemono-support.cab $(BUILDDIR)/winemono-support.msi $(IMAGEDIR)/support/
.PHONY: winemono-support.msi winemono-support.cab
imagedir-targets: winemono-support.msi

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

$(BUILDDIR)/.runtimemsitables-built: $(BUILDDIR)/.imagedir-built $(SRCDIR)/msi-tables/runtime/*.idt $(SRCDIR)/tools/build-msi-tables.sh $(BUILDDIR)/genfilehashes.exe $(SRCDIR)/Makefile
	$(MONO_ENV) WHICHMSI=runtime MSI_VERSION=$(MSI_VERSION) CABFILENAME=$(BUILDDIR_ABS)/image.cab TABLEDIR=$(BUILDDIR_ABS)/msi-tables/runtime TABLESRCDIR=$(SRCDIR_ABS)/msi-tables/runtime IMAGEDIR=$(IMAGEDIR_ABS) ROOTDIR=MONODIR CABINET='#image.cab' GENFILEHASHES=$(BUILDDIR_ABS)/genfilehashes.exe WINE=$(WINE) sh $(SRCDIR)/tools/build-msi-tables.sh
	touch $@

$(OUTDIR)/wine-mono-$(MSI_VERSION).msi: $(BUILDDIR)/.runtimemsitables-built
	rm -f "$@"
	$(WINE) winemsibuilder -i '$(shell $(WINE) winepath -w $@)' $(BUILDDIR)/msi-tables/runtime/*.idt
	$(WINE) winemsibuilder -a '$(shell $(WINE) winepath -w $@)' image.cab '$(shell $(WINE) winepath -w $(BUILDDIR)/image.cab)'

msi: $(OUTDIR)/wine-mono-$(MSI_VERSION).msi
.PHONY: msi

clean-msi:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION).msi
.PHONY: clean-msi
clean: clean-msi

$(OUTDIR)/wine-mono-bin-$(MSI_VERSION).tar.gz: $(BUILDDIR)/.imagedir-built
	cd $(IMAGEDIR)/..; tar czf $(OUTDIR_ABS)/wine-mono-bin-$(MSI_VERSION).tar.gz --transform 's:^$(notdir $(IMAGEDIR_ABS)):wine-mono-$(MSI_VERSION):g' $(notdir $(IMAGEDIR_ABS))

targz: $(OUTDIR)/wine-mono-bin-$(MSI_VERSION).tar.gz
.PHONY: targz

clean-targz:
	rm -f $(OUTDIR)/wine-mono-bin-$(MSI_VERSION).tar.gz
.PHONY: clean-targz
clean: clean-targz

