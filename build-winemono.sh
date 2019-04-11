#!/bin/sh

# setup

CURDIR="`pwd`"
BUILDDIR="$CURDIR"
SRCDIR="$CURDIR"
OUTDIR="$CURDIR"
MINGW_x86=i686-w64-mingw32
MINGW_x86_64=x86_64-w64-mingw32
ORIGINAL_PATH="$PATH"
REBUILD=0
WINE=${WINE:-`which wine`}
BUILD_TESTS=0
BUILD_IMAGE=0
BUILD_TAR=0
BUILD_MSI=0
USE_MONOLITE=0
MSI_VERSION=4.8.99

if test -d "$CURDIR/output"; then
    OUTDIR="$CURDIR/output"
fi

usage ()
{
    cat <<EOF
Usage: build-winemono.sh [OPTIONS]

where OPTIONS are:

 -m MINGW   Sets the x86 MINGW target name to be passed to configure [$MINGW_x86]
 -M MINGW   Sets the amd64 MINGW target name to be passed to configure [$MINGW_x86_64]
 -t         Build the mono test suite
 -r         Rebuild (skips configure)
 -b PATH    Sets the directory for intermediate build files [$BUILDDIR]
 -o PATH    Sets the directory for output files [$OUTDIR]
 -l         Fetch and use monolite
 -i         Build the image/ directory only
 -a         Build the -bin tarball
 -I         Build the .msi installer
EOF

    exit 1
}

while getopts "d:m:D:M:b:o:trhliaI" opt; do
    case "$opt" in
	m) MINGW_x86="$OPTARG" ;;
	M) MINGW_x86_64="$OPTARG" ;;
	t) BUILD_TESTS=1 ;;
	i) BUILD_IMAGE=1 ;;
	a) BUILD_TAR=1 ;;
	I) BUILD_MSI=1 ;;
	r) REBUILD=1 ;;
	b) BUILDDIR="$OPTARG" ;;
	o) OUTDIR="$OPTARG" ;;
	l) USE_MONOLITE=1 ;;
	*) usage ;;
    esac
done

if test $BUILD_IMAGE = 0 -a $BUILD_TAR = 0 -a $BUILD_MSI = 0; then
	BUILD_IMAGE=1
	BUILD_TAR=1
	BUILD_MSI=1
fi

# function definitions

cross_build_mono ()
{
    # Unset CC, if it is set, otherwise the build scripts will attempt to use the wrong compiler
    unset CC

    local MINGW=$1
    local ARCH=$2

    if test 1 != $REBUILD; then
        rm -rf "$BUILDDIR/build-cross-$ARCH"
    fi

    if test ! -d "$BUILDDIR/build-cross-$ARCH"; then
        mkdir "$BUILDDIR/build-cross-$ARCH"
    fi

    cd "$BUILDDIR/build-cross-$ARCH"
    if test 1 != $REBUILD || test ! -e Makefile; then
        CPPFLAGS="-gdwarf-2 -gstrict-dwarf" "$SRCDIR"/mono/configure --prefix="$BUILDDIR/build-cross-$ARCH-install" --build=$BUILD --target=$MINGW --host=$MINGW --with-tls=none --disable-mcs-build --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG=false mono_cv_clang=no || exit 1
        sed -e 's/-lgcc_s//' -i libtool
    fi
    WINEPREFIX=/dev/null make $MAKEOPTS || exit 1
    cd "$BUILDDIR/build-cross-$ARCH/support"
    WINEPREFIX=/dev/null make $MAKEOPTS || exit 1
    rm -rf "$BUILDDIR/build-cross-$ARCH-install"
    cd "$BUILDDIR/build-cross-$ARCH"
    make install || exit 1
    cd "$CURDIR"

    mkdir -p "$BUILDDIR/image/bin"
    if test -f "$BUILDDIR/build-cross-$ARCH-install/bin/libmono-2.0.dll"; then
        cp "$BUILDDIR/build-cross-$ARCH-install/bin/libmono-2.0.dll" "$BUILDDIR/image/bin/libmono-2.0-$ARCH.dll"
    elif test -f "$BUILDDIR/build-cross-$ARCH-install/bin/libmonosgen-2.0.dll"; then
        cp "$BUILDDIR/build-cross-$ARCH-install/bin/libmonosgen-2.0.dll" "$BUILDDIR/image/bin/libmono-2.0-$ARCH.dll"
    elif test -f "$BUILDDIR/build-cross-$ARCH-install/bin/libmonoboehm-2.0.dll"; then
        cp "$BUILDDIR/build-cross-$ARCH-install/bin/libmonoboehm-2.0.dll" "$BUILDDIR/image/bin/libmono-2.0-$ARCH.dll"
    else
        echo cannot find libmono dll
        exit 1
    fi
    mkdir -p "$BUILDDIR/image/lib"
    cp "$BUILDDIR/build-cross-$ARCH/support/.libs/libMonoPosixHelper.dll" "$BUILDDIR/image/lib/MonoPosixHelper-$ARCH.dll" || exit 1

    # build libtest.dll for the runtime tests
    if test x$BUILD_TESTS = x1; then
        cd "$BUILDDIR/build-cross-$ARCH/mono/tests"
        make libtest.la || exit 1
        mkdir "$OUTDIR/tests-runtime-$ARCH"
        cp .libs/libtest-0.dll "$OUTDIR/tests-runtime-$ARCH/libtest.dll" || exit 1
    fi

	# build FNA deps
    if test ! -d "$BUILDDIR/build-cross-$ARCH/SDL2"; then
        mkdir "$BUILDDIR/build-cross-$ARCH/SDL2"
    fi

    cd "$BUILDDIR/build-cross-$ARCH/SDL2"
    if test 1 != $REBUILD || test ! -e Makefile; then
        CC="${MINGW}-gcc -static-libgcc" CXX="${MINGW}-g++ -static-libgcc -static-libstdc++" "$SRCDIR"/SDL2/configure --build=$BUILD --target=$MINGW --host=$MINGW PKG_CONFIG=false || exit 1
    fi
    make $MAKEOPTS TARGET=libSDL2-$ARCH.la || exit 1
    cp "$BUILDDIR/build-cross-$ARCH/SDL2/build/.libs/SDL2-$ARCH.dll" "$BUILDDIR/image/lib/SDL2-$ARCH.dll" || exit 1
	
    if test ! -d "$BUILDDIR/build-cross-$ARCH/FAudio"; then
        mkdir "$BUILDDIR/build-cross-$ARCH/FAudio"
    fi

	cd "$BUILDDIR/build-cross-$ARCH/FAudio"
    if test 1 != $REBUILD || test ! -e Makefile; then
        cmake -DCMAKE_TOOLCHAIN_FILE="$SRCDIR/toolchain-$ARCH.cmake" -DCMAKE_C_COMPILER="${MINGW}-gcc" -DCMAKE_CXX_COMPILER="${MINGW}-g++" -DSDL2_INCLUDE_DIRS="$BUILDDIR/build-cross-$ARCH/SDL2/include;$SRCDIR/SDL2/include" -DSDL2_LIBRARIES="$BUILDDIR/build-cross-$ARCH/SDL2/build/.libs/libSDL2-$ARCH.dll.a" "$SRCDIR"/FNA/lib/FAudio || exit 1
    fi
    make $MAKEOPTS || exit 1
    cp "$BUILDDIR/build-cross-$ARCH/FAudio/FAudio.dll" "$BUILDDIR/image/lib/FAudio-$ARCH.dll" || exit 1
	
    if test ! -d "$BUILDDIR/build-cross-$ARCH/Theorafile"; then
        mkdir "$BUILDDIR/build-cross-$ARCH/Theorafile"
    fi

	cd "$BUILDDIR/build-cross-$ARCH/Theorafile"
	make $MAKEOPTS "CC=${MINGW}-gcc" -f "$SRCDIR/FNA/lib/Theorafile/Makefile" || exit 1
    cp "$BUILDDIR/build-cross-$ARCH/Theorafile/libtheorafile.dll" "$BUILDDIR/image/lib/libtheorafile-$ARCH.dll" || exit 1
	
    if test ! -d "$BUILDDIR/build-cross-$ARCH/MojoShader"; then
        mkdir "$BUILDDIR/build-cross-$ARCH/MojoShader"
    fi

	cd "$BUILDDIR/build-cross-$ARCH/MojoShader"
    if test 1 != $REBUILD || test ! -e Makefile; then
        cmake -DCMAKE_TOOLCHAIN_FILE="$BUILDDIR/toolchain-$ARCH.cmake" -DCMAKE_C_COMPILER="${MINGW}-gcc" -DCMAKE_CXX_COMPILER="${MINGW}-g++" -DBUILD_SHARED=ON -DPROFILE_D3D=OFF -DPROFILE_BYTECODE=OFF -DPROFILE_ARB1=OFF -DPROFILE_ARB1_NV=OFF -DPROFILE_METAL=OFF -DCOMPILER_SUPPORT=OFF -DFLIP_VIEWPORT=ON -DDEPTH_CLIPPING=ON -DXNA4_VERTEXTEXTURE=ON "$SRCDIR"/FNA/lib/MojoShader || exit 1
    fi
    make $MAKEOPTS || exit 1
    cp "$BUILDDIR/build-cross-$ARCH/MojoShader/libmojoshader.dll" "$BUILDDIR/image/lib/libmojoshader-$ARCH.dll" || exit 1
}

build_cli ()
{
    # build mono
    if test 1 != $REBUILD; then
        rm -rf "$BUILDDIR/build-cross-cli"
    fi

    if test ! -d "$BUILDDIR/build-cross-cli"; then
        mkdir "$BUILDDIR/build-cross-cli"
    fi

    cd "$BUILDDIR/build-cross-cli"
    if test 1 != $REBUILD || test ! -e Makefile; then
        "$SRCDIR"/mono/configure --prefix="$BUILDDIR/build-cross-cli-install" --with-mcs-docs=no --disable-system-aot || exit 1
    fi

	# put a System.Native library somewhere monolite can find it during the build
	cd "$BUILDDIR/build-cross-cli/mono/native"
	make $MAKEOPTS || exit 1
	mkdir "$BUILDDIR/build-cross-cli/mono/lib/"
	cp .libs/libmono-native.so "$BUILDDIR/build-cross-cli/mono/lib/libSystem.Native.so" || exit 1

    cd "$BUILDDIR/build-cross-cli"
    if test 1 = $USE_MONOLITE; then
        make get-monolite-latest || exit 1
    elif test -e $SRCDIR/monolite/mcs.exe; then
        MONOLITE_PATH="$SRCDIR/monolite"
    fi
    if test x != x$MONOLITE_PATH; then
        make $MAKEOPTS "EXTERNAL_RUNTIME=MONO_PATH=$MONOLITE_PATH $BUILDDIR/build-cross-cli/mono/mini/mono-sgen" "EXTERNAL_MCS=\$(EXTERNAL_RUNTIME) $MONOLITE_PATH/mcs.exe" || exit 1
        make HOST_PLATFORM=win32 $MAKEOPTS "EXTERNAL_RUNTIME=MONO_PATH=$MONOLITE_PATH $BUILDDIR/build-cross-cli/mono/mini/mono-sgen" "EXTERNAL_MCS=\$(EXTERNAL_RUNTIME) $MONOLITE_PATH/mcs.exe" || exit 1
    else
        make $MAKEOPTS || exit 1
        make HOST_PLATFORM=win32 $MAKEOPTS || exit 1
    fi
    rm -rf "$BUILDDIR/build-cross-cli-install"
    rm -rf "$BUILDDIR/build-cross-cli-win32-install"
    make HOST_PLATFORM=win32 install || exit 1
    mv "$BUILDDIR/build-cross-cli-install" "$BUILDDIR/build-cross-cli-win32-install" || exit 1
    make install || exit 1
    cd "$CURDIR"

    # build tests if necessary
    if test x$BUILD_TESTS = x1; then
        for profile in "$SRCDIR"/mono/mcs/class/lib/net_?_?; do
			profile=`basename "$profile"`
            if test -e "$SRCDIR/mono/mcs/class/lib/$profile/nunit-console.exe"; then
                cd "$SRCDIR/mono/mcs/class/"
                make $MAKEOPTS test PROFILE=$profile || exit 1

                rm -rf "$OUTDIR/tests-$profile"
                mkdir "$OUTDIR/tests-$profile"
                cd "$SRCDIR/mono/mcs/class/lib/$profile"*/tests
                cp ${profile}_*_test.dll "$OUTDIR/tests-$profile" || exit 1
                
                # extra files used by tests
                cd "$SRCDIR/mono/mcs/class"
                mkdir -p "$OUTDIR/tests-$profile/Test/System.Drawing"
                cp -r System.Drawing/Test/System.Drawing/bitmaps "$OUTDIR/tests-$profile/Test/System.Drawing" || exit 1
                cp -r System.Windows.Forms/Test/resources "$OUTDIR/tests-$profile/Test" || exit 1

                cd "$SRCDIR/mono/mcs/class/lib/$profile"
                cp nunit* "$OUTDIR/tests-$profile" || exit 1
            fi
        done

        cd "$BUILDDIR/build-cross-cli/mono/tests"
        make $MAKEOPTS test-local || exit 1

        # runtime tests
        for dirname in ls "$OUTDIR"/tests-runtime-*; do
            cp *.exe *.dll "$dirname"
        done
    fi

    # set up for further builds
    export PATH="$BUILDDIR/build-cross-cli-install/bin":$PATH
    export LD_LIBRARY_PATH="$BUILDDIR/build-cross-cli-install/lib":$LD_LIBRARY_PATH
    export MONO_GAC_PREFIX="$BUILDDIR/build-cross-cli-install"
    export MONO_CFG_DIR="$BUILDDIR/build-cross-cli-install/etc"

    # build mono-basic
    cd "$SRCDIR/mono-basic"
    ./configure --prefix="$BUILDDIR/build-cross-cli-win32-install" || exit 1
    make $MAKEOPTS || exit 1
    make install || exit 1

	cd "$SRCDIR/FNA"
	make release || exit 1
	gacutil -i "$SRCDIR/FNA/bin/Release/FNA.dll" -root "$BUILDDIR/build-cross-cli-win32-install/lib" || exit 1

	# build FNA.NetStub
	cd "$SRCDIR/FNA.NetStub"
	make || exit 1
	gacutil -i "$SRCDIR/FNA.NetStub/bin/Strongname/FNA.NetStub.dll" -root "$BUILDDIR/build-cross-cli-win32-install/lib" || exit 1

	# build XNA forwarding libraries
	cd "$SRCDIR/FNA/abi"
	make || exit 1
	for dll in "$SRCDIR"/FNA/abi/Microsoft.Xna.*.dll; do
		gacutil -i "$dll" -root "$BUILDDIR/build-cross-cli-win32-install/lib" || exit 1
	done

    # build image/ directory
    mkdir -p "$BUILDDIR/image/lib"
    cp -r "$BUILDDIR/build-cross-cli-win32-install/etc" "$BUILDDIR/image/"
    cp -r "$BUILDDIR/build-cross-cli-win32-install/lib/mono" "$BUILDDIR/image/lib"

    cp "$BUILDDIR/build-cross-cli-win32-install/etc/mono/2.0/machine.config" "$BUILDDIR/image-support/Microsoft.NET/Framework64/v1.1.4322/CONFIG/machine.config"
    cp "$BUILDDIR/build-cross-cli-win32-install/etc/mono/2.0/machine.config" "$BUILDDIR/image-support/Microsoft.NET/Framework64/v2.0.50727/CONFIG/machine.config"
    cp "$BUILDDIR/build-cross-cli-win32-install/etc/mono/4.0/machine.config" "$BUILDDIR/image-support/Microsoft.NET/Framework64/v4.0.30319/CONFIG/machine.config"

    cp "$BUILDDIR/build-cross-cli-win32-install/etc/mono/2.0/machine.config" "$BUILDDIR/image-support/Microsoft.NET/Framework/v1.1.4322/CONFIG/machine.config"
    cp "$BUILDDIR/build-cross-cli-win32-install/etc/mono/2.0/machine.config" "$BUILDDIR/image-support/Microsoft.NET/Framework/v2.0.50727/CONFIG/machine.config"
    cp "$BUILDDIR/build-cross-cli-win32-install/etc/mono/4.0/machine.config" "$BUILDDIR/image-support/Microsoft.NET/Framework/v4.0.30319/CONFIG/machine.config"

    cp "$BUILDDIR/build-cross-cli-win32-install/lib/mono/2.0-api/mscorlib.dll" "$BUILDDIR/image-support/Microsoft.NET/Framework64/v1.1.4322/mscorlib.dll"
    cp "$BUILDDIR/build-cross-cli-win32-install/lib/mono/2.0-api/mscorlib.dll" "$BUILDDIR/image-support/Microsoft.NET/Framework64/v2.0.50727/mscorlib.dll"
    cp "$BUILDDIR/build-cross-cli-win32-install/lib/mono/4.0/mscorlib.dll" "$BUILDDIR/image-support/Microsoft.NET/Framework64/v4.0.30319/mscorlib.dll"

    cp "$BUILDDIR/build-cross-cli-win32-install/lib/mono/2.0-api/mscorlib.dll" "$BUILDDIR/image-support/Microsoft.NET/Framework/v1.1.4322/mscorlib.dll"
    cp "$BUILDDIR/build-cross-cli-win32-install/lib/mono/2.0-api/mscorlib.dll" "$BUILDDIR/image-support/Microsoft.NET/Framework/v2.0.50727/mscorlib.dll"
    cp "$BUILDDIR/build-cross-cli-win32-install/lib/mono/4.0/mscorlib.dll" "$BUILDDIR/image-support/Microsoft.NET/Framework/v4.0.30319/mscorlib.dll"

	mcs "$SRCDIR/csc-wrapper.cs" /d:VERSION40 -out:"$BUILDDIR"/image-support/Microsoft.NET/Framework/v4.0.30319/csc.exe -r:Mono.Posix || exit 1
	mcs "$SRCDIR/csc-wrapper.cs" /d:VERSION20 -out:"$BUILDDIR"/image-support/Microsoft.NET/Framework/v2.0.50727/csc.exe -r:Mono.Posix || exit 1

	cp "$BUILDDIR"/image-support/Microsoft.NET/Framework/v4.0.30319/csc.exe "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v4.0.30319/csc.exe
	cp "$BUILDDIR"/image-support/Microsoft.NET/Framework/v2.0.50727/csc.exe "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v2.0.50727/csc.exe

    # remove debug files
	cd "$BUILDDIR"
    for f in `find image|grep -E '\.(mdb|pdb)$'`; do
        rm "$f"
    done
	cd "$CURDIR"
}

build_msi_filesystem ()
{
	CABFILENAME=$1
	IMAGEDIR=$2
	TABLEDIR=$3
	ROOTDIR=$4
	CABINET=$5

    export PATH="$BUILDDIR/build-cross-cli-install/bin":$PATH
    export LD_LIBRARY_PATH="$BUILDDIR/build-cross-cli-install/lib":$LD_LIBRARY_PATH
    export MONO_GAC_PREFIX="$BUILDDIR/build-cross-cli-install"
    export MONO_CFG_DIR="$BUILDDIR/build-cross-cli-install/etc"

    mcs "$SRCDIR"/genfilehashes.cs -out:"$BUILDDIR"/genfilehashes.exe -r:Mono.Posix || exit 1

    IMAGECABWINPATH=`"${WINE}" winepath -w "$CABFILENAME"`

	cd "${IMAGEDIR}"

	FILEKEY_EXPR='s/\//\\/g'
	FILEKEY_REV_EXPR='s/\\/\//g'
	DIRKEY_EXPR='s/\//|/g'

    find . | cut -d '/' -f2- | while read -r f; do
        if test . = "$f"; then
            continue
        fi
        FILEKEY=`echo $f|sed -e "$FILEKEY_EXPR"`
		DIRKEY=`echo $f|sed -e "$DIRKEY_EXPR"`
		PARENT=`dirname "$f"`
		BASENAME=`basename "$f"`

		if test $PARENT = .; then
			PARENTKEY=$ROOTDIR
		else
			PARENTKEY=`echo $PARENT|sed -e "$DIRKEY_EXPR"`
		fi

		if test -d "$f"; then
			GUID=`uuidgen -s -n 26a7bdb4-1612-4e2b-a26e-e548a12e4d48 -N "$f" | tr [a-z] [A-Z]`
			KEYPATH=`find "$f" -maxdepth 1 -type f|sort|head -n 1|sed -e "$FILEKEY_EXPR"`

			case "$f" in
			Microsoft.NET/Framework64*) CONDITION='(VersionNT64)';;
			*) CONDITION=;;
			esac

			printf '%s\t{%s}\t%s\t0\t%s\t%s\n' "$DIRKEY" "$GUID" "$DIRKEY" "$CONDITION" "$KEYPATH" >> ${TABLEDIR}/component.idt
			printf "%s\t%s\n" "$DIRKEY" "$DIRKEY" >> ${TABLEDIR}/createfolder.idt
			printf "%s\t%s\t%s\n" "$DIRKEY" "$PARENTKEY" "$BASENAME" >> ${TABLEDIR}/directory.idt
			printf "wine_mono\t%s\n" "$DIRKEY" >> ${TABLEDIR}/featurecomponents.idt
		elif test -f "$f"; then
			true
		else
			# Don't include symlinks
			rm "$f" || exit 1
		fi
    done

	mono "$BUILDDIR/genfilehashes.exe" >> ${TABLEDIR}/msifilehash.idt

	"${WINE}" cabarc -m mszip -r -p N "$IMAGECABWINPATH" * || exit 1

	# We can't dictate the order of files in the cab, so read it back to find the sequence numbers.
	SEQ=0
	rm -f "${TABLEDIR}/sequence"

    "${WINE}" cabarc L "$IMAGECABWINPATH" | sed -e "$FILEKEY_REV_EXPR" | while read -r f; do
        FILEKEY=`echo $f|sed -e "$FILEKEY_EXPR"`
		FILESIZE=`ls -l "$f" | awk '{print $5}'`
		PARENT=`dirname "$f"`
		BASENAME=`basename "$f"`
		SEQ=`expr $SEQ + 1`

		if test $PARENT = .; then
			PARENTKEY=$ROOTDIR
		else
			PARENTKEY=`echo $PARENT|sed -e "$DIRKEY_EXPR"`
		fi

		printf '%s\t%s\t%s\t%s\t\t\t\t%s\n' "$FILEKEY" "$PARENTKEY" "$BASENAME" "$FILESIZE" "$SEQ" >> ${TABLEDIR}/file.idt
		printf "%s" "$SEQ" > ${TABLEDIR}/sequence
	done

	printf '1\t%s\t\t%s\t\t\n' `cat "${TABLEDIR}/sequence"` "$CABINET" >> ${TABLEDIR}/media.idt
}

build_support_msi ()
{
	MSIFILENAME=$BUILDDIR/image/support/winemono-support.msi
	CABFILENAME=$BUILDDIR/image/support/winemono-support.cab
	TABLEDIR=$BUILDDIR/build-msi-tables/support/

    rm -f "${CABFILENAME}" "${MSIFILENAME}" "${TABLEDIR}"/*.idt || exit 1

	mkdir -p "${TABLEDIR}"
	cp "${BUILDDIR}"/msi-tables/support/*.idt "${TABLEDIR}"

	build_msi_filesystem "$CABFILENAME" "$BUILDDIR/image-support" "$TABLEDIR" WindowsFolder 'winemono-support.cab'

	PRODUCTCODE=`uuidgen -s -n 27ec5e1a-7f2f-445c-9e78-76ae42a51b6d -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	PACKAGECODE=`uuidgen -s -n 5b2a0add-9ec1-4c3c-b749-2c7d96db4656 -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	printf 'ProductCode\t{%s}\n' $PRODUCTCODE >> "$TABLEDIR"/property.idt
	printf 'ProductVersion\t%s\n' $MSI_VERSION >> "$TABLEDIR"/property.idt
	printf '9\t{%s}\n' $PACKAGECODE >> "$TABLEDIR"/summaryinformation.idt
	printf '{DE624609-C6B5-486A-9274-EF0B854F6BC5}\t\t%s\t\t0\t\tOLDERVERSIONBEINGUPGRADED\n' $MSI_VERSION >> "$TABLEDIR"/upgrade.idt

    MSIWINPATH=`"${WINE}" winepath -w "$MSIFILENAME"`

	cd "${BUILDDIR}"

    "$WINE" winemsibuilder -i "${MSIWINPATH}" build-msi-tables/support/*.idt || exit 1
}

build_runtime_msi ()
{
	MSIFILENAME=$OUTDIR/winemono.msi
	CABFILENAME=$BUILDDIR/image.cab
	TABLEDIR=$BUILDDIR/build-msi-tables/runtime/

    rm -f "${CABFILENAME}" "${MSIFILENAME}" "${TABLEDIR}"/*.idt || exit 1

	mkdir -p "${TABLEDIR}"
	cp "${BUILDDIR}"/msi-tables/runtime/*.idt "${TABLEDIR}"

	build_msi_filesystem "$CABFILENAME" "$BUILDDIR/image" "$TABLEDIR" MONODIR '#image.cab'

	SUPPORT_PRODUCTCODE=`uuidgen -s -n 27ec5e1a-7f2f-445c-9e78-76ae42a51b6d -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	PRODUCTCODE=`uuidgen -s -n e3d60378-6160-4d62-9105-1a321b78891e -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	PACKAGECODE=`uuidgen -s -n 27abb979-e12d-4a3a-95d8-f42c2027a693 -N "$MSI_VERSION" | tr [a-z] [A-Z]`
	printf 'ProductCode\t{%s}\n' $PRODUCTCODE >> "$TABLEDIR"/property.idt
	printf 'ProductVersion\t%s\n' $MSI_VERSION >> "$TABLEDIR"/property.idt
	printf '9\t{%s}\n' $PACKAGECODE >> "$TABLEDIR"/summaryinformation.idt
	printf '{DF105CC2-8FA2-4367-B1D3-95C63C0941FC}\t4.8.0\t%s\t\t0\t\tOLDERVERSIONBEINGUPGRADED\n' $MSI_VERSION >> "$TABLEDIR"/upgrade.idt
	printf 'REMOVESUPPORT\t1122\tWindowsFolder\tmsiexec /x {%s}\t\n' $SUPPORT_PRODUCTCODE >> "$TABLEDIR"/customaction.idt

    IMAGECABWINPATH=`"${WINE}" winepath -w "$CABFILENAME"`
    MSIWINPATH=`"${WINE}" winepath -w "$MSIFILENAME"`

	cd "${BUILDDIR}"

    "$WINE" winemsibuilder -i "${MSIWINPATH}" build-msi-tables/runtime/*.idt || exit 1
    "$WINE" winemsibuilder -a "${MSIWINPATH}" image.cab "$IMAGECABWINPATH" || exit 1
}

build_runtime_archive ()
{
	cd "$BUILDDIR"

	tar czf "$OUTDIR"/wine-mono-bin.tar.gz --transform 's:^image:wine-mono-'$MSI_VERSION':g' image
}

sanity_checks ()
{
    # Make sure a few programs are around, otherwise we'll fail later on:
    if test ! -x "$WINE"
    then
        echo "You need to have wine installed. You can set the path to it with WINE=/path/to/wine"
        exit 1
    fi

    if test 1 != $USE_MONOLITE && \
       test ! -e $SRCDIR/monolite/mcs.exe && \
       test ! -x "`which mcs 2>/dev/null`"
    then
        echo "You need to have mcs from mono installed or use the -l switch."
        exit 1
    fi
}

# build

sanity_checks

cd "$SRCDIR"/mono

if test 1 != $REBUILD || test ! -e configure; then
    # create configure script and such
    if test ! -f ./autogen.sh; then
        echo "./autogen.sh was not found! Did you forget to use --recursive when cloning?"
        exit 1
    else
        NOCONFIGURE=yes ./autogen.sh || exit 1
    fi

    BUILD="`./config.guess`"

    if test -f ./Makefile; then
    rm -rf autom4te.cache
    fi
fi

cd "$CURDIR"

rm -rf "$BUILDDIR"/image
mkdir "$BUILDDIR"/image
rm -rf "$BUILDDIR"/image-support
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework/v1.1.4322/CONFIG
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework/v2.0.50727/CONFIG
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework/v4.0.30319/CONFIG
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework/v3.0/"windows communication foundation"
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework/v3.0/wpf
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v1.1.4322/CONFIG
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v2.0.50727/CONFIG
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v4.0.30319/CONFIG
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v3.0/"windows communication foundation"
mkdir -p "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v3.0/wpf

cross_build_mono "$MINGW_x86_64" x86_64

cross_build_mono "$MINGW_x86" x86

build_cli

mkdir "$BUILDDIR"/image/support || exit 1
cp "$SRCDIR"/dotnetfakedlls.inf "$BUILDDIR"/image/support/ || exit 1
cp "$SRCDIR"/security.config "$BUILDDIR"/image-support/Microsoft.NET/Framework/v2.0.50727/CONFIG/security.config || exit 1
cp "$SRCDIR"/security.config "$BUILDDIR"/image-support/Microsoft.NET/Framework64/v2.0.50727/CONFIG/security.config || exit 1

build_support_msi

if test $BUILD_MSI = 1; then
	build_runtime_msi
fi

if test $BUILD_TAR = 1; then
	build_runtime_archive
fi

