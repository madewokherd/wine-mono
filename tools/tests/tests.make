
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

TEST_INSTALL_FILES = $(TEST_RAW_FILES:%=tools/tests/%)

tools/tests/%.exe: tools/tests/%.il $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) ilasm -target:exe -output:$@ $<

tools/tests/%.exe: tools/tests/%.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc -unsafe -target:exe -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $< $(shell sed -n '/CSCFLAGS=/s/^.*CSCFLAGS=//p' $<)

tools/tests/%.dll: tools/tests/%.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc -target:library -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $< $(shell sed -n '/CSCFLAGS=/s/^.*CSCFLAGS=//p' $<)

tools/tests/privatepath1.exe: tools/tests/testcslib1.dll

tools/tests/privatepath2.exe: tools/tests/testcslib1.dll tools/tests/testcslib2.dll

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
