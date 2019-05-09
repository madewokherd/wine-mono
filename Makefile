
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

MONO_MAKEFILES=$(shell cd $(SRCDIR); find mono -name Makefile.am)

MONO_MONO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono/mono $(SRCDIR)/mono/libgc)
SDL2_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL2)
FAUDIO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FAudio)
SDLIMAGE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL_image_compact)

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
endef

$(eval $(call MINGW_TEMPLATE,x86))
$(eval $(call MINGW_TEMPLATE,x86_64))

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
