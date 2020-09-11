
TEST_CS_EXE_SRCS = \
	arraypadding.cs \
	marshalansi.cs \
	privatepath1.cs \
	privatepath2.cs \
	webbrowsertest.cs

TEST_RAW_FILES = \
	privatepath2.exe.config \
	privatepath1.exe.config

TEST_IL_EXE_SRCS = \
	xnatest.il

TEST_CLR_EXE_TARGETS = $(TEST_CS_EXE_SRCS:%.cs=tools/tests/%.exe) $(TEST_IL_EXE_SRCS:%.il=tools/tests/%.exe)

ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
TEST_NUNIT_TARGETS = \
	net_4_x_PresentationCore_test.dll
endif

TEST_INSTALL_FILES = $(TEST_RAW_FILES:%=tools/tests/%)

tools/tests/%.exe: tools/tests/%.il $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) ilasm -target:exe -output:$@ $<

tools/tests/%.exe: tools/tests/%.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc -unsafe -target:exe -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $< $(shell sed -n '/CSCFLAGS=/s/^.*CSCFLAGS=//p' $<)

tools/tests/%.dll: tools/tests/%.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc -target:library -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $< $(shell sed -n '/CSCFLAGS=/s/^.*CSCFLAGS=//p' $<)

tools/tests/privatepath1.exe: tools/tests/testcslib1.dll

tools/tests/privatepath2.exe: tools/tests/testcslib1.dll tools/tests/testcslib2.dll

tools/tests/net_4_x_%_test.dll: $(BUILDDIR)/nunitlite.dll
	$(MONO_ENV) csc -target:library -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $(foreach path,$(filter %/.built,$^),-r:$(dir $(path))/$(notdir $(realpath $(dir $(path)))).dll) $(filter %.cs,$^)

tools/tests/net_4_x_PresentationCore_test.dll: \
	tools/tests/PresentationCore/TextFormatter.cs

TEST_NUNIT_EXTRADEPS_net_4_x_PresentationCore_test.dll = \
	$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built \
	$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built

define nunit_target_template
tools/tests/$(1): $$(TEST_NUNIT_EXTRADEPS_$(1))
$$(TESTS_OUTDIR)/tests-clr/$(1): $$(SRCDIR)/tools/tests/$(1) tests-clr
	mkdir -p $$(TESTS_OUTDIR)/tests-clr
	$$(MONO_ENV) MONO_PATH=$$(subst $$(eval) ,:,$$(foreach path,$$(TEST_NUNIT_EXTRADEPS_$(1)),$$(dir $$(path)))) mono $(TESTS_OUTDIR)/tests-clr/nunit-lite-console.exe $$< -explore:$$(TESTS_OUTDIR)/tests-clr/$(1).testlist && test -f $$(TESTS_OUTDIR)/tests-clr/$(1).testlist
	cp $$< $$@
tests: $$(TESTS_OUTDIR)/tests-clr/$(1)
endef

$(foreach target,$(TEST_NUNIT_TARGETS), $(eval $(call nunit_target_template,$(target))))

tools-tests-all: $(TEST_CLR_EXE_TARGETS) $(TEST_INSTALL_FILES) tools/tests/tests.make
.PHONY: tools-tests-all

tools-tests-install: tools-tests-all $(BUILDDIR)/set32only.exe
	for i in $(TEST_CLR_EXE_TARGETS); do \
		cp $$i $(TESTS_OUTDIR)/tests-x86 ; \
		$(WINE) $(BUILDDIR)/set32only.exe $(TESTS_OUTDIR)/tests-x86/$$(basename $$i) ; \
		cp $$i $(TESTS_OUTDIR)/tests-x86_64 ; \
	done
	for i in $(TEST_INSTALL_FILES); do \
		cp $$i $(TESTS_OUTDIR)/tests-x86 ; \
		cp $$i $(TESTS_OUTDIR)/tests-x86_64 ; \
	done
	mkdir -p $(TESTS_OUTDIR)/tests-x86/lib1
	cp tools/tests/testcslib1.dll $(TESTS_OUTDIR)/tests-x86/lib1
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/lib1
	cp tools/tests/testcslib1.dll $(TESTS_OUTDIR)/tests-x86_64/lib1
	mkdir -p $(TESTS_OUTDIR)/tests-x86/lib2
	cp tools/tests/testcslib2.dll $(TESTS_OUTDIR)/tests-x86/lib2
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/lib2
	cp tools/tests/testcslib2.dll $(TESTS_OUTDIR)/tests-x86_64/lib2
.PHONY: tools-tests-install

tests: tools-tests-install

clean-tools-tests:
	rm -f $(SRCDIR)/tools/tests/*.dll $(SRCDIR)/tools/tests/*.exe
.PHONY: clean-tools-tests
clean: clean-tools-tests
