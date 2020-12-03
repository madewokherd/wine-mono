FNA3D_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FNA3D)

define MINGW_TEMPLATE +=

# FNA3D
$$(BUILDDIR)/FNA3D-$(1)/Makefile: $$(SRCDIR)/FNA/lib/FNA3D/CMakeLists.txt $$(SRCDIR)/fna3d.make $$(BUILDDIR)/SDL2-$(1)/.built $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	cd $$(@D); $$(MINGW_ENV) cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DSDL2_INCLUDE_DIRS="$$(BUILDDIR_ABS)/SDL2-$(1)/include;$$(SRCDIR_ABS)/SDL2/include" -DSDL2_LIBRARIES="$$(BUILDDIR_ABS)/SDL2-$(1)/build/.libs/libSDL2-$(1).dll.a" -DDISABLE_D3D11=1 $$(SRCDIR_ABS)/FNA/lib/FNA3D

$$(BUILDDIR)/FNA3D-$(1)/.built: $$(BUILDDIR)/FNA3D-$(1)/Makefile $$(FNA3D_SRCS) $$(MINGW_DEPS)
	+$$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/FNA3D-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/FNA3D-$(1)/.built

FNA3D-$(1).dll: $$(BUILDDIR)/FNA3D-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/FNA3D-$(1)/FNA3D.dll" "$$(IMAGEDIR)/lib/FNA3D-$(1).dll"
.PHONY: FNA3D-$(1).dll
imagedir-targets: FNA3D-$(1).dll

clean-build-FNA3D-$(1):
	rm -rf $$(BUILDDIR)/FNA3D-$(1)
.PHONY: clean-build-FNA3D-$(1)
clean-build: clean-build-FNA3D-$(1)

endef

