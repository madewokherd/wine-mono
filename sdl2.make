
SDL2_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL2)

define MINGW_TEMPLATE +=

# note: we explicitly disable vsscanf as msvcrt doesn't support it and mingw-w64's wrapper is buggy
$$(BUILDDIR)/SDL2-$(1)/Makefile: $$(SRCDIR)/SDL2/configure $$(SRCDIR)/sdl2.make $$(MINGW_DEPS)
	mkdir -p $$(@D)
	cd $$(BUILDDIR)/SDL2-$(1); $$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1)) $$$${CFLAGS:--g -O2}" CXXFLAGS="$$(PDB_CFLAGS_$(1)) $$$${CXXFLAGS:--g -O2}" LDFLAGS="$$(PDB_LDFLAGS_$(1))" CC="$$(MINGW_$(1))-gcc -static-libgcc" CXX="$$(MINGW_$(1))-g++ -static-libgcc -static-libstdc++" $$(SRCDIR_ABS)/SDL2/configure --build=$$(shell $$(SRCDIR)/mono/config.guess) --target=$$(MINGW_$(1)) --host=$$(MINGW_$(1)) PKG_CONFIG=false ac_cv_func_vsscanf=no --disable-hidapi

$$(BUILDDIR)/SDL2-$(1)/.built: $$(BUILDDIR)/SDL2-$(1)/Makefile $$(SDL2_SRCS) $$(MINGW_DEPS)
	+WINEPREFIX=/dev/null $$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/SDL2-$(1) TARGET=libSDL2-$(1).la
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/SDL2-$(1)/.built

SDL2-$(1).dll: $$(BUILDDIR)/SDL2-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/SDL2-$(1)/build/.libs/SDL2-$(1).dll" "$$(IMAGEDIR)/lib/SDL2-$(1).dll"
.PHONY: SDL2-$(1).dll
imagedir-targets: SDL2-$(1).dll

SDL2.dll: SDL2-$(1).dll
.PHONY: SDL2.dll

clean-build-SDL2-$(1):
	rm -rf $$(BUILDDIR)/SDL2-$(1)
.PHONY: clean-build-SDL2-$(1)
clean-build: clean-build-SDL2-$(1)

endef

