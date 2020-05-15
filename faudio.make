FAUDIO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FAudio)

define MINGW_TEMPLATE +=

# FAudio
$$(BUILDDIR)/FAudio-$(1)/Makefile: $$(SRCDIR)/FNA/lib/FAudio/CMakeLists.txt $$(SRCDIR)/faudio.make $$(BUILDDIR)/SDL2-$(1)/.built $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	cd $$(@D); $$(MINGW_ENV) cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DSDL2_INCLUDE_DIRS="$$(BUILDDIR_ABS)/SDL2-$(1)/include;$$(SRCDIR_ABS)/SDL2/include" -DSDL2_LIBRARIES="$$(BUILDDIR_ABS)/SDL2-$(1)/build/.libs/libSDL2-$(1).dll.a" $$(SRCDIR_ABS)/FNA/lib/FAudio

$$(BUILDDIR)/FAudio-$(1)/.built: $$(BUILDDIR)/FAudio-$(1)/Makefile $$(FAUDIO_SRCS) $$(MINGW_DEPS)
	+$$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/FAudio-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/FAudio-$(1)/.built

FAudio-$(1).dll: $$(BUILDDIR)/FAudio-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/FAudio-$(1)/FAudio.dll" "$$(IMAGEDIR)/lib/FAudio-$(1).dll"
.PHONY: FAudio-$(1).dll
imagedir-targets: FAudio-$(1).dll

clean-build-FAudio-$(1):
	rm -rf $$(BUILDDIR)/FAudio-$(1)
.PHONY: clean-build-FAudio-$(1)
clean-build: clean-build-FAudio-$(1)

endef

