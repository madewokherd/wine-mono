MOJOSHADER_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/MojoShader)

define MINGW_TEMPLATE +=

# libmojoshader
$$(BUILDDIR)/MojoShader-$(1)/Makefile: $$(SRCDIR)/FNA/lib/MojoShader/CMakeLists.txt $$(SRCDIR)/mojoshader.make $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	cd $$(@D); $$(MINGW_ENV) cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DBUILD_SHARED_LIBS=ON -DPROFILE_D3D=OFF -DPROFILE_BYTECODE=OFF -DPROFILE_ARB1=OFF -DPROFILE_ARB1_NV=OFF -DPROFILE_METAL=OFF -DCOMPILER_SUPPORT=OFF -DFLIP_VIEWPORT=ON -DDEPTH_CLIPPING=ON -DXNA4_VERTEXTEXTURE=ON $$(SRCDIR_ABS)/FNA/lib/MojoShader

$$(BUILDDIR)/MojoShader-$(1)/.built: $$(BUILDDIR)/MojoShader-$(1)/Makefile $$(MOJOSHADER_SRCS) $$(MINGW_DEPS)
	+$$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/MojoShader-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/MojoShader-$(1)/.built

libmojoshader-$(1).dll: $$(BUILDDIR)/MojoShader-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/MojoShader-$(1)/libmojoshader.dll" "$$(IMAGEDIR)/lib/libmojoshader-$(1).dll"
.PHONY: libmojoshader-$(1).dll
imagedir-targets: libmojoshader-$(1).dll

clean-build-MojoShader-$(1):
	rm -rf $$(BUILDDIR)/MojoShader-$(1)
.PHONY: clean-build-MojoShader-$(1)
clean-build: clean-build-MojoShader-$(1)

endef

