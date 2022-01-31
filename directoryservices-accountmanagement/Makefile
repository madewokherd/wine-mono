
COMPILE_LIB=csc -target:library

BASEDIR=$(WINE_MONO_SRCDIR)/mono/external/corefx/src/System.DirectoryServices.AccountManagement/src

LIB_FLAGS=-unsafe -delaysign+ -keyfile:$(WINE_MONO_SRCDIR)/mono/mcs/class/ecma.pub -define:FLAVOR_WHIDBEY -define:PAPI_AD -define:PAPI_REGSAM -define:USE_CTX_CACHE -langversion:8.0 -nostdlib -noconfig -lib:$(MONO_PREFIX)/lib/mono/4.5-api

LIB_REFS=-r:mscorlib.dll -r:System.dll -r:System.Configuration.dll -r:System.Xml.dll -r:System.DirectoryServices.dll -r:System.DirectoryServices.Protocols.dll

LIB_SRCS=$(shell cat sources.list)

all: System.DirectoryServices.AccountManagement.dll

SR.generated.cs: $(BASEDIR)/Resources/Strings.resx $(RESX2SRID)
	mono $(RESX2SRID) $< SR System.DirectoryServices.AccountManagement > $@ || rm -f $@

Resources/Strings.resources: $(BASEDIR)/Resources/Strings.resx
	mkdir -p $(@D)
	resgen $< $@

EMBEDDED_RESOURCES=$(shell cat embeddedresources.list)

EMBEDDED_RES_PATHS=$(foreach f,$(EMBEDDED_RESOURCES),Resources/$(f))

embeddedresources.flags: embeddedresources.list
	for i in `cat embeddedresources.list`; do printf -- '-resource:Resources/%s,%s\n' $$i `echo $$i|sed "s:/:.:g"|sed "s:Strings.resources:SR.resources:g"`; done > $@ || rm -f $@

System.DirectoryServices.AccountManagement.dll: sources.list $(LIB_SRCS) embeddedresources.flags $(EMBEDDED_RES_PATHS) $(ACCESSIBILITY_DLL)
	$(COMPILE_LIB) $(LIB_FLAGS) $(LIB_REFS) -out:$@ @sources.list @embeddedresources.flags
	sn -R $@ $(WINE_MONO_SRCDIR)/mono/mcs/class/mono.snk
