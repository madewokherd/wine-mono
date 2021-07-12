
VBRUNTIME_BASE=$(SRCDIR)/mono-basic/vbruntime/Microsoft.VisualBasic

VBRUNTIME_SRCS= \
	$(VBRUNTIME_BASE)/AssemblyInfo.vb \
	$(VBRUNTIME_BASE)/Helper.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Hashtable.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/ArrayList.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/ApplicationBase.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/AssemblyInfo.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/AuthenticationMode.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/BuiltInRole.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/BuiltInRoleConverter.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/CantStartSingleInstanceException.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/ConsoleApplicationBase.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/WebUser.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/UnhandledExceptionEventArgs.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/UnhandledExceptionEventHandler.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/NoStartupFormException.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/ShutdownEventHandler.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/ShutdownMode.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/StartupEventArgs.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/StartupEventHandler.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/StartupNextInstanceEventArgs.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/StartupNextInstanceEventHandler.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/User.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/WindowsFormsApplicationBase.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.ApplicationServices/WindowsFormsApplicationContext.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/BooleanType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/ByteType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/CharArrayType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/CharType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/Conversions.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/OptionCompareAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/NewLateBinding.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/ObjectFlowControl.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/LikeOperator.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/InternalErrorException.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/ExceptionUtils.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/DesignerGeneratedAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/OptionTextAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/TypeCombinations.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/VBErrors.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/Versioned.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/DateType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/DecimalType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/DoubleType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/FlowControl.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/HostServices.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/IncompleteInitialization.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/IntegerType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/IVbHost.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/LateBinder.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/LateBinding.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/LongType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/ObjectType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/Operators.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/ProjectData.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/ShortType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/SingleType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/StandardModuleAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/StaticLocalInitFlag.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/StringType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.CompilerServices/Utils.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Audio.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Audio.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Clock.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Computer.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Computer.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/ComputerInfo.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/ComputerInfo.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Keyboard.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Keyboard.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Mouse.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Mouse.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/MyWebClient.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Network.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/NetworkAvailableEventArgs.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/NetworkAvailableEventHandler.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/MyProgressDialog.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Ports.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/Ports.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/ServerComputer.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Devices/ServerComputer.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/DeleteDirectoryOption.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/FieldType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/FileSystem.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/FileSystemOperation.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/FileSystemOperationUI.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/FileSystemOperationUIQuestion.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/MalformedLineException.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/RecycleOption.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/SearchOption.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/SpecialDirectories.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/TextFieldParser.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/UICancelOption.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.FileIO/UIOption.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Logging/AspLog.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Logging/DiskSpaceExhaustedOption.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Logging/FileLogTraceListener.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Logging/Log.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Logging/LogFileCreationScheduleOption.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.Logging/LogFileLocation.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.MyServices.Internal/ContextValue.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.MyServices/ClipboardProxy.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.MyServices/FileSystemProxy.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.MyServices/RegistryProxy.jvm.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.MyServices/RegistryProxy.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.MyServices/SpecialDirectoriesProxy.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.OSSpecific/LinuxDriver.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.OSSpecific/OSDriver.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic.OSSpecific/Win32Driver.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/AppWinStyle.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/CallType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Collection.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/ComClassAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/CompareMethod.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Constants.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/ControlChars.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Conversion.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/AudioPlayMode.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/FileData.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Globals.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/SpcInfo.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/TabInfo.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/VBFixedStringAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/VBFixedArrayAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/MyGroupCollectionAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/DateAndTime.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/DateFormat.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/DateInterval.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/DueDate.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/ErrObject.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/FileAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/FileSystem.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Financial.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/FirstDayOfWeek.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/FirstWeekOfYear.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/HideModuleNameAttribute.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Information.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Interaction.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/MsgBoxResult.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/MsgBoxStyle.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/OpenAccess.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/OpenMode.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/OpenShare.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/Strings.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/TriState.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/VariantType.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/VBMath.vb \
	$(VBRUNTIME_BASE)/Microsoft.VisualBasic/VbStrConv.vb \
	$(VBRUNTIME_BASE)/MonoTODOAttribute.vb

VBRUNTIME_RESOURCES= \
	$(BUILDDIR)/Microsoft.VisualBasic/strings2.resources \
	$(VBRUNTIME_BASE)/strings.resources

$(BUILDDIR)/Microsoft.VisualBasic/strings2.txt: $(VBRUNTIME_BASE)/strings.txt $(VBRUNTIME_BASE)/strings-only2.txt
	mkdir -p $(BUILDDIR)/Microsoft.VisualBasic
	cat $^ > $@

$(BUILDDIR)/Microsoft.VisualBasic/strings2.resources: $(BUILDDIR)/mono-unix/.installed $(BUILDDIR)/Microsoft.VisualBasic/strings2.txt
	$(MONO_ENV) resgen2 $(BUILDDIR)/Microsoft.VisualBasic/strings2.txt $@

$(BUILDDIR)/Microsoft.VisualBasic.dll: $(BUILDDIR)/mono-unix/.installed $(VBRUNTIME_SRCS) $(VBRUNTIME_RESOURCES) $(VBRUNTIME_BASE)/msfinal.pub $(VBRUNTIME_BASE)/mono.snk
	$(MONO_ENV) vbc -target:library -debug+ -out:$@ -define:NET_VER=4.5 $(foreach res,$(VBRUNTIME_RESOURCES),-res:$(res)) -r:System.dll -r:mscorlib.dll -r:System.Windows.Forms.dll -r:System.Data.dll -r:System.Drawing.dll -r:System.Web.dll -r:System.Xml.dll -vbruntime- -define:_MYTYPE="Empty" -define:DONTSIGN=True -delaysign+ -keyfile:$(VBRUNTIME_BASE)/msfinal.pub -optionstrict+ -imports:System,System.Collections,System.Data,System.Diagnostics,System.Collections.Generic -noconfig $(VBRUNTIME_SRCS)
	$(MONO_ENV) sn -R $@ $(VBRUNTIME_BASE)/mono.snk

Microsoft.VisualBasic.dll: $(BUILDDIR)/Microsoft.VisualBasic.dll
	$(MONO_ENV) gacutil -i $(BUILDDIR)/Microsoft.VisualBasic.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.VisualBasic.dll
imagedir-targets: Microsoft.VisualBasic.dll

clean-build-mono-basic:
	rm -rf $(BUILDDIR)/Microsoft.VisualBasic
	rm -f $(BUILDDIR)/Microsoft.VisualBasic.dll
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

$(BUILDDIR)/net_4_x_Microsoft.VisualBasic_test.dll: $(BUILDDIR)/nunitlite.dll $(BUILDDIR)/Microsoft.VisualBasic.dll $(patsubst %, $(SRCDIR)/mono-basic/vbruntime/Test/%, $(VBRUNTIME_TEST_VB_SRCS))
	cd $(SRCDIR_ABS)/mono-basic/vbruntime/Test && $(MONO_ENV) vbc $(VBRUNTIME_TEST_VB_SRCS) -libpath:../../class/lib/net_4_5/ -libpath:$(BUILDDIR_ABS) -vbruntime:$(BUILDDIR_ABS)/Microsoft.VisualBasic.dll -r:nunitlite.dll -imports:System,System.Collections,Microsoft.VisualBasic,NUnit.Framework -optionstrict- -target:library -out:$(BUILDDIR_ABS)/net_4_x_Microsoft.VisualBasic_test.dll

$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll: $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_test.dll tests-clr
	$(MONO_ENV) MONO_PATH=$(SRCDIR)/mono-basic/class/lib/net_4_5 mono $(TESTS_OUTDIR)/tests-clr/nunit-lite-console.exe $< -explore:$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll.testlist && test -f $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll.testlist
	cp $< $@

$(BUILDDIR)/net_4_x_Microsoft.VisualBasic_CS_test.dll: $(BUILDDIR)/nunitlite.dll $(BUILDDIR)/Microsoft.VisualBasic.dll $(patsubst %, $(SRCDIR)/mono-basic/vbruntime/Test/%, $(VBRUNTIME_TEST_CS_SRCS))
	cd $(SRCDIR_ABS)/mono-basic/vbruntime/Test && $(MONO_ENV) csc $(VBRUNTIME_TEST_CS_SRCS) -lib:../../class/lib/net_4_5/ -lib:$(BUILDDIR_ABS) -r:Microsoft.VisualBasic.dll -r:nunitlite.dll -target:library -out:$(BUILDDIR_ABS)/net_4_x_Microsoft.VisualBasic_CS_test.dll

$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll: $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_CS_test.dll tests-clr
	$(MONO_ENV) MONO_PATH=$(SRCDIR)/mono-basic/class/lib/net_4_5 mono $(TESTS_OUTDIR)/tests-clr/nunit-lite-console.exe $< -explore:$(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll.testlist && test -f $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll.testlist
	cp $< $@

tests: $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_test.dll $(TESTS_OUTDIR)/tests-clr/net_4_x_Microsoft.VisualBasic_CS_test.dll

clean-tests-mono-basic:
	rm -f $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_test.dll
	rm -f $(BUILDDIR)/net_4_x_Microsoft.VisualBasic_CS_test.dll
.PHONY: clean-tests-mono-basic
clean-build: clean-tests-mono-basic

