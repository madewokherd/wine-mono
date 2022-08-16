
RESX2SR=mono $(WINE_MONO_SRCDIR)/mono/mcs/class/lib/build-linux/resx2sr.exe

COMPILE_LIB=csc -target:library

LIB_FLAGS=-unsafe -delaysign+ -keyfile:../reactive.pub -langversion:9.0 -lib:$(MONO_PREFIX)/lib/mono/4.5-api

LIB_REFS=-r:mscorlib.dll -r:System.dll -r:System.Configuration.dll -r:System.Core.dll

LIB_SRCS=$(shell cat sources.list)

all: System.Speech.dll

ExceptionStringTable.resources: Resources/Strings.resx
	resgen $< $@

EMBEDDED_RESOURCES=$(shell cat embeddedresources.list)

EMBEDDED_RES_PATHS=$(EMBEDDED_RESOURCES)

embeddedresources.flags: embeddedresources.list
	for i in `cat embeddedresources.list`; do printf -- '-resource:%s,%s\n' $$i `echo $$i|sed "s:/:.:g"|sed "s:Common.SR:System.Windows.Forms.DataVisualization.Charting.SR:g"`; done > $@ || rm -f $@

System.Speech.dll: sources.list $(LIB_SRCS) $(SIBLING_PATHS) embeddedresources.flags $(EMBEDDED_RES_PATHS)
	$(COMPILE_LIB) $(LIB_FLAGS) $(LIB_REFS) $(SIBLING_REFS) -out:$@ @sources.list @embeddedresources.flags
	sn -R $@ ../mono.snk

clean:
	rm -f ExceptionStringTable.resources System.Speech.dll embeddedresources.flags
