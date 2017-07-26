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
USE_MONOLITE=0

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
EOF

    exit 1
}

while getopts "d:m:D:M:b:o:trhl" opt; do
    case "$opt" in
	m) MINGW_x86="$OPTARG" ;;
	M) MINGW_x86_64="$OPTARG" ;;
	t) BUILD_TESTS=1 ;;
	r) REBUILD=1 ;;
	b) BUILDDIR="$OPTARG" ;;
	o) OUTDIR="$OPTARG" ;;
	l) USE_MONOLITE=1 ;;
	*) usage ;;
    esac
done


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
    cp "$BUILDDIR/build-cross-$ARCH/support/.libs/libMonoPosixHelper.dll" "$BUILDDIR/image/bin/MonoPosixHelper-$ARCH.dll" || exit 1

    # build libtest.dll for the runtime tests
    if test x$BUILD_TESTS = x1; then
        cd "$BUILDDIR/build-cross-$ARCH/mono/tests"
        make libtest.la || exit 1
        mkdir "$OUTDIR/tests-runtime-$ARCH"
        cp .libs/libtest-0.dll "$OUTDIR/tests-runtime-$ARCH/libtest.dll" || exit 1
    fi
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
    if test 1 = $USE_MONOLITE; then
        make get-monolite-latest || exit 1
    elif test -e $SRCDIR/monolite/mcs.exe; then
        MONOLITE_PATH="$SRCDIR/monolite"
    fi
    if test x != x$MONOLITE_PATH; then
        make $MAKEOPTS "EXTERNAL_RUNTIME=MONO_PATH=$MONOLITE_PATH $BUILDDIR/build-cross-cli/mono/mini/mono-sgen" "EXTERNAL_MCS=\$(EXTERNAL_RUNTIME) $MONOLITE_PATH/mcs.exe" || exit 1
    else
        make $MAKEOPTS || exit 1
    fi
    rm -rf "$BUILDDIR/build-cross-cli-install"
    make install || exit 1
    cd "$CURDIR"

    # build tests if necessary
    if test x$BUILD_TESTS = x1; then
        for profile in "$SRCDIR"/mono/mcs/class/lib/net_?_?; do
            if test -e "$SRCDIR/mono/mcs/class/lib/$profile/nunit-console.exe"; then
                cd "$SRCDIR/mono/mcs/class/"
                make $MAKEOPTS test PROFILE=$profile || exit 1

                rm -rf "$OUTDIR/tests-$profile"
                mkdir "$OUTDIR/tests-$profile"
                cd "$SRCDIR/mono/mcs/class"
                cp */*_test_$profile.dll "$OUTDIR/tests-$profile"
                
                # System.Drawing test's extra files
                mkdir -p "$OUTDIR/tests-$profile/Test/System.Drawing"
                cp -r System.Drawing/Test/System.Drawing/bitmaps "$OUTDIR/tests-$profile/Test/System.Drawing"

                cd "$SRCDIR/mono/mcs/class/lib/$profile"
                cp nunit* "$OUTDIR/tests-$profile"
            fi
        done

        cd "$BUILDDIR/build-cross-cli/mono/tests"
        make tests || exit 1

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
    ./configure --prefix="$BUILDDIR/build-cross-cli-install" || exit 1
    make $MAKEOPTS || exit 1
    make install || exit 1

    # build image/ directory
    mkdir -p "$BUILDDIR/image/lib"
    cp -r "$BUILDDIR/build-cross-cli-install/etc" "$BUILDDIR/image/"
    cp -r "$BUILDDIR/build-cross-cli-install/lib/mono" "$BUILDDIR/image/lib"

    cp "$BUILDDIR/build-cross-cli-install/etc/mono/2.0/machine.config" "$BUILDDIR/image/1.1-machine.config"
    cp "$BUILDDIR/build-cross-cli-install/etc/mono/2.0/machine.config" "$BUILDDIR/image/2.0-machine.config"
    cp "$BUILDDIR/build-cross-cli-install/etc/mono/4.0/machine.config" "$BUILDDIR/image/4.0-machine.config"

    cp "$BUILDDIR/build-cross-cli-install/lib/mono/2.0-api/mscorlib.dll" "$BUILDDIR/image/1.1-mscorlib.dll"
    cp "$BUILDDIR/build-cross-cli-install/lib/mono/2.0-api/mscorlib.dll" "$BUILDDIR/image/2.0-mscorlib.dll"
    cp "$BUILDDIR/build-cross-cli-install/lib/mono/4.0/mscorlib.dll" "$BUILDDIR/image/4.0-mscorlib.dll"

    # remove debug files
	cd "$BUILDDIR"
    for f in `find image|grep '\.mdb$'`; do
        rm "$f"
    done
	cd "$CURDIR"
}

build_directorytable ()
{
    printf 'Directory\tDirectory_Parent\tDefaultDir\n'
    printf 's72\tS72\tl255\n'
    printf 'Directory\tDirectory\n'

    printf 'TARGETDIR\t\tSourceDir\n'
    printf 'MONODIR\tMONOBASEDIR\tmono-2.0:.\n'
    printf 'MONOBASEDIR\tWindowsFolder\tmono:.\n'
    printf 'WindowsFolder\tTARGETDIR\t.\n'
    printf 'WindowsDotNet\tWindowsFolder\tMicrosoft.NET\n'
    printf 'WindowsDotNetFramework\tWindowsDotNet\tFramework\n'
    printf 'WindowsDotNetFramework11\tWindowsDotNetFramework\tv1.1.4322\n'
    printf 'WindowsDotNetFramework11Config\tWindowsDotNetFramework11\tCONFIG\n'
    printf 'WindowsDotNetFramework20\tWindowsDotNetFramework\tv2.0.50727\n'
    printf 'WindowsDotNetFramework20Config\tWindowsDotNetFramework20\tCONFIG\n'
    printf 'WindowsDotNetFramework30\tWindowsDotNetFramework\tv3.0\n'
    printf 'WindowsDotNetFramework30wcf\tWindowsDotNetFramework30\twindows communication foundation\n'
    printf 'WindowsDotNetFramework30wpf\tWindowsDotNetFramework30\twpf\n'
    printf 'WindowsDotNetFramework40\tWindowsDotNetFramework\tv4.0.30319\n'
    printf 'WindowsDotNetFramework40Config\tWindowsDotNetFramework40\tCONFIG\n'

    cd "$BUILDDIR/image"

    for f in `find . -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        KEY=`echo $f|sed -e 's/\//|/g'`
        DIRNAME=`dirname $f|sed -e 's/\//|/g'`
        if test x. = x$DIRNAME; then
            DIRNAME=MONODIR
        fi
        BASENAME=`basename $f`
        printf '%s\t%s\t%s\n' "$KEY" "$DIRNAME" "$BASENAME"
    done

    cd "$CURDIR"
}

build_componenttable ()
{
    printf 'Component\tComponentId\tDirectory_\tAttributes\tCondition\tKeyPath\n'
    printf 's72\tS38\ts72\ti2\tS255\tS72\n'
    printf 'Component\tComponent\n'

    printf 'mono-registry\t{93BE4304-497C-4ACB-A0FD-1C3695C011B4}\tWindowsDotNetFramework\t4\t\tDotNetFrameworkInstallRoot\n'
    printf 'mono-registry64\t{E088D122-0696-4137-BC4E-C999303B4BE2}\tWindowsDotNetFramework\t260\t\tDotNetFrameworkInstallRoot\n'
    printf 'config-1.1\t{0DA29B5A-2050-4200-92EE-442D1EE6CF96}\tWindowsDotNetFramework11Config\t0\t\t1.1-machine.config\n'
    printf 'config-2.0\t{ABB0BF6A-6610-4E45-8194-64D596667621}\tWindowsDotNetFramework20Config\t0\t\t2.0-machine.config\n'
    printf 'config-4.0\t{511C0294-4504-4FC9-B5A7-E85CCEE95C6B}\tWindowsDotNetFramework40Config\t0\t\t4.0-machine.config\n'
    printf 'dotnet-folder\t{22DCE198-F30F-4E74-AEC6-D089B844A878}\tWindowsDotNet\t0\t\t\n' # needed to remove the folder
    printf 'framework-folder\t{41B3A67B-63F4-4491-A53C-9E792BE5A889}\tWindowsDotNetFramework\t0\t\t\n'
    printf 'framework11-folder\t{20F5741D-4655-400D-8373-7607A84D2478}\tWindowsDotNetFramework11\t0\t\tmscorlib.dll\n'
    printf 'framework20-folder\t{B845FD54-09B7-467C-800F-205A142F2F20}\tWindowsDotNetFramework20\t0\t\tmscorlib.dll\n'
    printf 'framework30-folder\t{C3221C80-F9D2-41B5-91E1-F6ADBB05ABBC}\tWindowsDotNetFramework30\t0\t\t\n'
    printf 'framework30wcf-folder\t{1ECAD22C-31C2-4BAC-AC74-78883C396FAB}\tWindowsDotNetFramework30wcf\t0\t\t\n'
    printf 'framework30wpf-folder\t{3C146462-0CAF-4F07-83E6-A75A2A5DE961}\tWindowsDotNetFramework30wpf\t0\t\t\n'
    printf 'framework40-folder\t{29ECF991-3E9E-4D23-B0B2-874631642B13}\tWindowsDotNetFramework40\t0\t\tmscorlib.dll\n'
    printf 'monobase-folder\t{BE46D94A-7443-4B5C-9B91-6A83815365AB}\tMONOBASEDIR\t0\t\t\n'
    printf 'mono-folder\t{FD7F9172-4E35-4DF5-BD6A-FB7B795D9346}\tMONODIR\t0\t\t\n'

    cd "$BUILDDIR/image"

    for f in `find . -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        KEY=`echo $f|sed -e 's/\//|/g'`
        if test ! -f "$SRCDIR/component-guids/${KEY}.guid"; then
            uuidgen | tr [a-z] [A-Z] > $SRCDIR/component-guids/${KEY}.guid
        fi
        GUID=`cat "$SRCDIR/component-guids/${KEY}.guid"`
        KEYPATH=`find "$f" -maxdepth 1 -type f|sort|head -n 1|sed -e 's/\//!/g'`
        printf '%s\t{%s}\t%s\t0\t\t%s\n' "$KEY" "$GUID" "$KEY" "$KEYPATH"
    done

    cd "$CURDIR"
}

build_createfoldertable ()
{
    printf 'Directory_\tComponent_\n'
    printf 's72\ts72\n'
    printf 'CreateFolder\tDirectory_\tComponent_\n'

    printf 'WindowsDotNet\tdotnet-folder\n'
    printf 'WindowsDotNetFramework\tframework-folder\n'
    printf 'WindowsDotNetFramework11\tframework11-folder\n'
    printf 'WindowsDotNetFramework20\tframework20-folder\n'
    printf 'WindowsDotNetFramework30\tframework30-folder\n'
    printf 'WindowsDotNetFramework30wcf\tframework30wcf-folder\n'
    printf 'WindowsDotNetFramework30wpf\tframework30wpf-folder\n'
    printf 'WindowsDotNetFramework40\tframework40-folder\n'
    printf 'MONOBASEDIR\tmonobase-folder\n'
    printf 'MONODIR\tmono-folder\n'

    cd "$BUILDDIR/image"

    for f in `find . -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        FILE=`find "$f" -maxdepth 1 -type f`
        if test ! "$FILE"; then
            KEY=`echo $f|sed -e 's/\//|/g'`
            printf '%s\t%s\n' "$KEY" "$KEY"
        fi
    done

    cd "$CURDIR"
}

build_featurecomponentstable ()
{
    printf 'Feature_\tComponent_\n'
    printf 's38\ts72\n'
    printf 'FeatureComponents\tFeature_\tComponent_\n'

    printf 'wine_mono\tmono-registry\n'
    printf 'wine_mono\tmono-registry64\n'
    printf 'wine_mono\tconfig-1.1\n'
    printf 'wine_mono\tconfig-2.0\n'
    printf 'wine_mono\tconfig-4.0\n'
    printf 'wine_mono\tdotnet-folder\n'
    printf 'wine_mono\tframework-folder\n'
    printf 'wine_mono\tframework11-folder\n'
    printf 'wine_mono\tframework20-folder\n'
    printf 'wine_mono\tframework30-folder\n'
    printf 'wine_mono\tframework30wcf-folder\n'
    printf 'wine_mono\tframework30wpf-folder\n'
    printf 'wine_mono\tframework40-folder\n'
    printf 'wine_mono\tmonobase-folder\n'
    printf 'wine_mono\tmono-folder\n'

    cd "$BUILDDIR/image"

    for f in `find . -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        KEY=`echo $f|sed -e 's/\//|/g'`
        printf 'wine_mono\t%s\n' "$KEY"
    done

    cd "$CURDIR"
}

build_filetable ()
{
    printf 'File\tComponent_\tFileName\tFileSize\tVersion\tLanguage\tAttributes\tSequence\n'
    printf 's72\ts72\tl255\ti4\tS72\tS20\tI2\ti2\n'
    printf 'File\tFile\n'

    SEQ=0

    cd "$BUILDDIR/image"

    find . -type f | cut -d '/' -f2- | sort | while read -r f; do
        SEQ=`expr $SEQ + 1`
        KEY=`echo $f|sed -e 's/\//!/g'`
        FILESIZE=`ls -l "$f" | awk '{print $5}'`

        case $f in 1.1-machine.config)
            COMPONENT=config-1.1
            BASENAME=machine.config
        ;;
        2.0-machine.config)
            COMPONENT=config-2.0
            BASENAME=machine.config
        ;;
        2.0-security.config)
            COMPONENT=config-2.0
            BASENAME=security.config
        ;;
        4.0-machine.config)
            COMPONENT=config-4.0
            BASENAME=machine.config
        ;;
        1.1-mscorlib.dll)
            COMPONENT=framework11-folder
            BASENAME=mscorlib.dll
        ;;
        2.0-mscorlib.dll)
            COMPONENT=framework20-folder
            BASENAME=mscorlib.dll
        ;;
        4.0-mscorlib.dll)
            COMPONENT=framework40-folder
            BASENAME=mscorlib.dll
        ;;
        *)
            COMPONENT=`dirname "$f"|sed -e 's/\//|/g'`
            BASENAME=`basename "$f"`
        ;;
        esac

        printf '%s\t%s\t%s\t%s\t\t\t\t%s\n' "$KEY" "$COMPONENT" "$BASENAME" "$FILESIZE" "$SEQ"
    done

    cd "$CURDIR"
}

build_mediatable ()
{
    printf 'DiskId\tLastSequence\tDiskPrompt\tCabinet\tVolumeLabel\tSource\n'
    printf 'i2\ti4\tL64\tS255\tS32\tS72\n'
    printf 'Media\tDiskId\n'

    IMAGECAB_SEQ=`tail -n 1 msi-tables/file.idt|awk '{print $5}'`

    printf '1\t%s\t\t#image.cab\t\t' "$IMAGECAB_SEQ"
}

build_msifilehashtable ()
{
    printf 'File_\tOptions\tHashPart1\tHashPart2\tHashPart3\tHashPart4\n'
    printf 's72\ti2\ti4\ti4\ti4\ti4\n'
    printf 'MsiFileHash\tFile_\n'

    export PATH="$BUILDDIR/build-cross-cli-install/bin":$PATH
    export LD_LIBRARY_PATH="$BUILDDIR/build-cross-cli-install/lib":$LD_LIBRARY_PATH
    export MONO_GAC_PREFIX="$BUILDDIR/build-cross-cli-install"
    export MONO_CFG_DIR="$BUILDDIR/build-cross-cli-install/etc"

    cd "$SRCDIR"

    mcs genfilehashes.cs -out:"$BUILDDIR"/genfilehashes.exe -r:Mono.Posix || exit 1

    cd "$BUILDDIR/image"

    mono "$BUILDDIR/genfilehashes.exe" || exit 1

    cd "$CURDIR"
}

build_msi ()
{
	MSIFILENAME=$OUTDIR/winemono.msi
    rm -rf cab-contents
    rm -f "$BUILDDIR/image.cab" "${MSIFILENAME}"

    mkdir "$BUILDDIR/cab-contents"

    cd "$BUILDDIR/image"

    find . -type f | cut -d '/' -f2- | while read -r f; do
        KEY=`echo $f|sed -e 's/\//!/g'`
        ln -s "$BUILDDIR/image/$f" "$BUILDDIR/cab-contents/$KEY"
    done

    cd "$BUILDDIR/cab-contents"

    IMAGECABWINPATH=`"${WINE}" winepath -w "$BUILDDIR"/image.cab`
    MSIWINPATH=`"${WINE}" winepath -w "$MSIFILENAME"`

    "${WINE}" cabarc -m mszip -r -p N "$IMAGECABWINPATH" *

    cd "$CURDIR"

    build_directorytable > msi-tables/directory.idt
    build_componenttable > msi-tables/component.idt
    build_createfoldertable > msi-tables/createfolder.idt
    build_featurecomponentstable > msi-tables/featurecomponents.idt
    build_filetable > msi-tables/file.idt
    build_mediatable > msi-tables/media.idt
    build_msifilehashtable > msi-tables/msifilehash.idt

    "$WINE" winemsibuilder -i "${MSIWINPATH}" msi-tables/*.idt
    "$WINE" winemsibuilder -a "${MSIWINPATH}" image.cab "$IMAGECABWINPATH"
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

cross_build_mono "$MINGW_x86_64" x86_64

cross_build_mono "$MINGW_x86" x86

build_cli

mkdir "$BUILDDIR"/image/support
cp "$SRCDIR"/dotnetfakedlls.inf "$BUILDDIR"/image/support/
cp "$SRCDIR"/security.config "$BUILDDIR"/image/2.0-security.config

build_msi

