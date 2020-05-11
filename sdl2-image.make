SDLIMAGE_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL_image_compact)

define MINGW_TEMPLATE +=

# SDL2_image
$$(BUILDDIR)/SDL_image_compact-$(1)/.built: $$(BUILDDIR)/SDL2-$(1)/.built $$(SDLIMAGE_SRCS) $$(MINGW_DEPS)
	mkdir -p $$(BUILDDIR)/SDL_image_compact-$(1)
	+$$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR_ABS)/SDL_image_compact-$(1) "CC=$$(MINGW_$(1))-gcc" SDL_LDFLAGS="$$(BUILDDIR_ABS)/SDL2-$(1)/build/.libs/libSDL2-$(1).dll.a" SDL_CFLAGS="-I$$(BUILDDIR_ABS)/SDL2-$(1)/include -I$$(SRCDIR_ABS)/SDL2/include" WICBUILD=1 -f $$(SRCDIR_ABS)/SDL_image_compact/Makefile
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/SDL_image_compact-$(1)/.built

SDL2_image-$(1).dll: $$(BUILDDIR)/SDL_image_compact-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/SDL_image_compact-$(1)/SDL2_image.dll" "$$(IMAGEDIR)/lib/SDL2_image-$(1).dll"
.PHONY: SDL2_image-$(1).dll
imagedir-targets: SDL2_image-$(1).dll

clean-build-SDL_image_compact-$(1):
	rm -rf $$(BUILDDIR)/SDL_image_compact-$(1)
.PHONY: clean-build-SDL_image_compact-$(1)
clean-build: clean-build-SDL_image_compact-$(1)

endef

