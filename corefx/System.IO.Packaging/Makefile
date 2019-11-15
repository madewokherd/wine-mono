
SRCDIR=$(WINE_MONO_SRCDIR)/mono/external/corefx/src/System.IO.Packaging/src

RESX2SR=$(WINE_MONO_SRCDIR)/mono/mcs/class/lib/build-linux/resx2sr.exe

COMPILE_LIB=csc -target:library

LIB_FLAGS=-unsafe -delaysign+ -keyfile:$(WINE_MONO_SRCDIR)/mono/mcs/class/ecma.pub -define:FEATURE_SERIALIZATION -langversion:8.0 -nostdlib -noconfig -lib:$(MONO_PREFIX)/lib/mono/4.5-api

LIB_REFS=-r:mscorlib.dll -r:System.dll -r:System.Xml.dll -r:System.Core.dll -r:System.IO.Compression.dll

LIB_SRCS=$(foreach i,$(shell cat sources.list),$(SRCDIR)/$(i))

all: System.IO.Packaging.dll

SR.generated.cs: $(SRCDIR)/Resources/Strings.resx $(RESX2SR)
	mono $(RESX2SR) $< > $@ || rm -f $@

SR.resources: $(SRCDIR)/Resources/Strings.resx
	resgen $< $@

LIB_SRCS += SR.generated.cs
LIB_SRCS += AssemblyInfo.cs
LIB_SRCS += $(WINE_MONO_SRCDIR)/mono/mcs/build/common/SR.cs

System.IO.Packaging.dll: sources.list $(LIB_SRCS) SR.resources
	$(COMPILE_LIB) $(LIB_FLAGS) $(LIB_REFS) -out:$@ $(LIB_SRCS) -resource:SR.resources
	sn -R $@ $(WINE_MONO_SRCDIR)/mono/mcs/class/mono.snk
