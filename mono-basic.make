MONO_BASIC_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono-basic)

$(SRCDIR)/mono-basic/build/config.make: $(SRCDIR)/mono-basic/configure $(SRCDIR)/mono-basic.make $(BUILDDIR)/mono-unix/.installed
	cd $(SRCDIR)/mono-basic && $(MONO_ENV) ./configure --prefix=$(BUILDDIR_ABS)/mono-basic-install

$(SRCDIR)/mono-basic/.built: $(SRCDIR)/mono-basic/build/config.make $(MONO_BASIC_SRCS) $(BUILDDIR)/.dir
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/mono-basic PROFILE_VBNC_FLAGS=/sdkpath:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.5-api
	touch $@

$(SRCDIR)/mono-basic/.installed: $(SRCDIR)/mono-basic/.built $(BUILDDIR)/.dir
	+$(MONO_ENV) $(MAKE) -C $(SRCDIR)/mono-basic PROFILE_VBNC_FLAGS=/sdkpath:$(BUILDDIR_ABS)/mono-unix-install/lib/mono/4.5-api install
	touch $@
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/mono-basic/.installed

mono-basic-image: $(SRCDIR)/mono-basic/.installed
	mkdir -p $(IMAGEDIR)/lib
	$(CP_R) $(BUILDDIR)/mono-basic-install/lib/mono $(IMAGEDIR)/lib
.PHONY: mono-basic-image
imagedir-targets: mono-basic-image

Microsoft.VisualBasic.dll: mono-basic-image

# FIXME: make clean for mono-basic source tree?
clean-build-mono-basic:
	rm -rf $(BUILDDIR)/mono-basic-install
.PHONY: clean-build-mono-basic
clean-build: clean-build-mono-basic

VBRUNTIME_TEST_VB_SRCS= \
    Microsoft.VisualBasic.CompilerServices/BooleanTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/ByteTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/ConversionsTests.vb \
    Microsoft.VisualBasic.CompilerServices/DateTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/DecimalTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/DoubleTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/IntegerTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/LateBindingTests.vb \
    Microsoft.VisualBasic.CompilerServices/LateBindingTests2.vb \
    Microsoft.VisualBasic.CompilerServices/LateBindingTests3.vb \
    Microsoft.VisualBasic.CompilerServices/LateBindingTests4.vb \
    Microsoft.VisualBasic.CompilerServices/LateBindingTests5.vb \
    Microsoft.VisualBasic.CompilerServices/LateBindingTests6.vb \
    Microsoft.VisualBasic.CompilerServices/LongTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/OperatorsTests.vb \
    Microsoft.VisualBasic.CompilerServices/ShortTypeTest.vb \
    Microsoft.VisualBasic.CompilerServices/SingleTypeTest.vb \
    Microsoft.VisualBasic.Devices/ComputerInfoTests.vb \
    Microsoft.VisualBasic.Devices/ComputerTests.vb \
    Microsoft.VisualBasic.Devices/ClockTests.vb \
    Microsoft.VisualBasic.Devices/AudioTests.vb \
    Microsoft.VisualBasic.Devices/KeyboardTests.vb \
    Microsoft.VisualBasic.Devices/MouseTests.vb \
    Microsoft.VisualBasic.Devices/NetworkTests.vb \
    Microsoft.VisualBasic.Devices/NetworkAvailableEventArgsTests.vb \
    Microsoft.VisualBasic.Devices/PortsTests.vb \
    Microsoft.VisualBasic.Devices/ServerComputerTests.vb \
    Microsoft.VisualBasic.FileIO/FileSystemTest.vb \
    Microsoft.VisualBasic/ErrObjectTests.vb \
    Microsoft.VisualBasic/ExceptionFilteringTests.vb \
    Microsoft.VisualBasic/GlobalsTests.vb \
    Microsoft.VisualBasic/Helper.vb \
    Microsoft.VisualBasic/InformationTests.vb \
    Microsoft.VisualBasic/InteractionTests.vb \
    Microsoft.VisualBasic/StringsTest.vb \
    Microsoft.VisualBasic/VBFixedArrayAttributeTest.vb \
    Microsoft.VisualBasic/VBFixedStringAttributeTest.vb	
# disabled due to compilation errors:
#    Microsoft.VisualBasic/FileSystemTestGenerated.vb \
#    Microsoft.VisualBasic/FileSystemTests.vb \
#    Microsoft.VisualBasic/FileSystemTests2.vb \

VBRUNTIME_TEST_CS_SRCS= \
    Microsoft.VisualBasic.CompilerServices/BooleanTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/DecimalTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/DoubleTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/IntegerTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/LongTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/ShortTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/SingleTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/StringTypeTest.cs \
    Microsoft.VisualBasic.CompilerServices/UtilsTest.cs \
    Microsoft.VisualBasic.FileIO/MalformedLineExceptionTest.cs \
    Microsoft.VisualBasic.FileIO/SpecialDirectoriesTest.cs \
    Microsoft.VisualBasic.FileIO/TextFieldParserTest.cs \
    Microsoft.VisualBasic.Logging/FileLogTraceListener.cs \
    Microsoft.VisualBasic.Logging/LogTest.cs \
    Microsoft.VisualBasic.Logging/AspLogTest.cs \
    Microsoft.VisualBasic.MyServices.Internal/ContextValueTest.cs \
    Microsoft.VisualBasic.MyServices/ClipboardProxyTest.cs \
    Microsoft.VisualBasic.MyServices/FileSystemProxyTest.cs \
    Microsoft.VisualBasic.MyServices/RegistryProxyTest.cs \
    Microsoft.VisualBasic.MyServices/SpecialDirectoriesProxyTest.cs \
    Microsoft.VisualBasic/CollectionTests.cs \
    Microsoft.VisualBasic/ConversionTests.cs \
    Microsoft.VisualBasic/DateAndTimeTests.cs \
    Microsoft.VisualBasic/ErrObjectTests.cs \
    Microsoft.VisualBasic/FinancialTests.cs \
    Microsoft.VisualBasic/InformationTests.cs \
    Microsoft.VisualBasic/StringsTest.cs \
    Microsoft.VisualBasic/VBMathTests.cs \
    Microsoft.VisualBasic/Helper.cs

$(BUILDDIR)/net_4_x_Microsoft.VisualBasic_test.dll: $(BUILDDIR)/nunitlite.dll $(SRCDIR)/mono-basic/.built $(patsubst %, $(SRCDIR)/mono-basic/vbruntime/Test/%, $(VBRUNTIME_TEST_VB_SRCS))
	cd $(SRCDIR_ABS)/mono-basic/vbruntime/Test && $(MONO_ENV) mono ../../class/lib/net_4_5/vbnc.exe $(VBRUNTIME_TEST_VB_SRCS) -libpath:../../class/lib/net_4_5/ -libpath:$(BUILDDIR_ABS) -r:nunitlite.dll -imports:System,System.Collections,Microsoft.VisualBasic,NUnit.Framework -optionstrict- -target:library -out:$(BUILDDIR_ABS)/net_4_x_Microsoft.VisualBasic_test.dll

$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll: $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_test.dll tests-clr
	$(MONO_ENV) MONO_PATH=$(SRCDIR)/mono-basic/class/lib/net_4_5 mono $(TESTS_OUTDIR)/tests-clr/nunit-lite-console.exe $< -explore:$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll.testlist && test -f $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll.testlist
	cp $< $@

$(BUILDDIR)/net_4_x_Microsoft.VisualBasic_CS_test.dll: $(BUILDDIR)/nunitlite.dll $(SRCDIR)/mono-basic/.built $(patsubst %, $(SRCDIR)/mono-basic/vbruntime/Test/%, $(VBRUNTIME_TEST_CS_SRCS))
	cd $(SRCDIR_ABS)/mono-basic/vbruntime/Test && $(MONO_ENV) csc $(VBRUNTIME_TEST_CS_SRCS) -lib:../../class/lib/net_4_5/ -lib:$(BUILDDIR_ABS) -r:Microsoft.VisualBasic.dll -r:nunitlite.dll -target:library -out:$(BUILDDIR_ABS)/net_4_x_Microsoft.VisualBasic_CS_test.dll

$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll: $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_CS_test.dll tests-clr
	$(MONO_ENV) MONO_PATH=$(SRCDIR)/mono-basic/class/lib/net_4_5 mono $(TESTS_OUTDIR)/tests-clr/nunit-lite-console.exe $< -explore:$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll.testlist && test -f $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll.testlist
	cp $< $@

tests: $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll

clean-tests-mono-basic:
	rm -f $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_test.dll
	rm -f $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_CS_test.dll
.PHONY: clean-tests-mono-basic
clean: clean-tests-mono-basic

