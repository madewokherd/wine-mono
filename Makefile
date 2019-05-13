
SRCDIR=$(dir $(MAKEFILE_LIST))
BUILDDIR=$(SRCDIR)/build
IMAGEDIR=$(SRCDIR)/image
OUTDIR=$(SRCDIR)

MINGW_x86=i686-w64-mingw32
MINGW_x86_64=x86_64-w64-mingw32

MSI_VERSION=4.8.99

SRCDIR_ABS=$(shell cd $(SRCDIR); pwd)
BUILDDIR_ABS=$(shell cd $(BUILDDIR); pwd)
IMAGEDIR_ABS=$(shell cd $(IMAGEDIR); pwd)
OUTDIR_ABS=$(shell cd $(OUTDIR); pwd)

HAVE_MONOLITE=$(shell test -e $(SRCDIR)/monolite/mcs.exe && echo 1 || echo 0)

MONO_MAKEFILES=$(shell cd $(SRCDIR); find mono -name Makefile.am)

MONO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono)
MONO_MONO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/mono $(SRCDIR)/mono/libgc)
MONO_LIBNATIVE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/native)
SDL2_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL2)
FAUDIO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FAudio)
SDLIMAGE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL_image_compact)
THEORAFILE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/Theorafile)
MOJOSHADER_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/MojoShader)

all:
	echo *** The makefile is a work in progress, please use build-winemono.sh for now ***
	false
.PHONY: all clean imagedir-targets tests

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

define MINGW_TEMPLATE =
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

$$(OUTDIR)/tests-$(1)/libmono.dll: $$(BUILDDIR)/mono-$(1)/.built
	+$$(MAKE) -C $$(BUILDDIR)/mono-$(1)/mono/tests libtest.la
	mkdir -p $$(@D)
	cp $$(BUILDDIR)/mono-$(1)/mono/tests/.libs/libtest-0.dll $$@
tests: $$(OUTDIR)/tests-$(1)/libmono.dll

clean-tests-$(1):
	rm -rf $$(OUTDIR)/tests-$(1)
.PHONY: clean-tests-$(1)
clean: clean-tests-$(1)

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

$(BUILDDIR)/mono-unix/.installed: $(BUILDDIR)/mono-unix/.built $(BUILDDIR)/mono-unix/.built-win32
	rm -rf $(BUILDDIR)/mono-unix-install $(BUILDDIR)/mono-win32-install
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix $(MONOLIST_OPTS) HOST_PLATFORM=win32 install
	mv $(BUILDDIR)/mono-unix-install $(BUILDDIR)/mono-win32-install
	+$(MAKE) -C $(BUILDDIR_ABS)/mono-unix $(MONOLIST_OPTS) install
	for f in `find $(BUILDDIR)/mono-win32-install|grep -E '\.(mdb|pdb)$$'`; do rm "$$f"; done
	touch $@

mono-image: $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(IMAGEDIR)/lib
	cp -r $(BUILDDIR)/mono-win32-install/etc $(IMAGEDIR)
	cp -r $(BUILDDIR)/mono-win32-install/lib/mono $(IMAGEDIR)/lib
.PHONY: mono-image
imagedir-targets: mono-image

clean-build-mono-unix:
	rm -rf $(BUILDDIR)/mono-unix $(BUILDDIR)/mono-unix-install $(BUILDDIR)/mono-win32-install
.PHONY: clean-build-mono-unix
clean-build: clean-build-mono-unix

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
