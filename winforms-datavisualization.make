WINFORMS_DATAVISUALIZATION_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/winforms-datavisualization)

$(SRCDIR)/winforms-datavisualization/src/System.Windows.Forms.DataVisualization/.built: $(BUILDDIR)/mono-unix/.installed $(WINFORMS_DATAVISUALIZATION_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

ifeq (1,$(ENABLE_DOTNET_CORE_WINFORMS))
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/winforms-datavisualization/src/System.Windows.Forms.DataVisualization/.built

System.Windows.Forms.DataVisualization.dll: $(SRCDIR)/winforms-datavisualization/src/System.Windows.Forms.DataVisualization/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/winforms-datavisualization/src/System.Windows.Forms.DataVisualization/System.Windows.Forms.DataVisualization.dll -root $(IMAGEDIR)/lib
.PHONY: System.Windows.Forms.DataVisualization.dll
imagedir-targets: System.Windows.Forms.DataVisualization.dll
endif
