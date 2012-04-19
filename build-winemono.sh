#!/bin/sh

# setup

CURDIR="`pwd`"
MINGW_x86=i686-w64-mingw32
MINGW_x86_64=x86_64-w64-mingw32
INSTALL_DESTDIR="$CURDIR"
ORIGINAL_PATH="$PATH"
REBUILD=0
WINE=${WINE:-wine}
MSIFILENAME=winemono.msi

usage ()
{
    cat <<EOF
Usage: build-winemono.sh [OPTIONS]

where OPTIONS are:

 -m MINGW   Sets the x86 MINGW target name to be passed to configure [$MINGW_x86]
 -M MINGW   Sets the amd64 MINGW target name to be passed to configure [$MINGW_x86_64]
 -t         Build the mono test suite
 -r         Rebuild (skips configure)
EOF

    exit 1
}

while getopts "d:m:D:M:trh" opt; do
    case "$opt" in
	m) MINGW_x86="$OPTARG" ;;
	M) MINGW_x86_64="$OPTARG" ;;
	t) BUILD_TESTS=1 ;;
	r) REBUILD=1 ;;
	*) usage ;;
    esac
done


# function definitions

cross_build_mono ()
{
    local MINGW=$1
    local ARCH=$2

    if test 1 != $REBUILD; then
        rm -rf "$CURDIR/build-cross-$ARCH"
    fi

    if test ! -d "$CURDIR/build-cross-$ARCH"; then
        mkdir "$CURDIR/build-cross-$ARCH"
    fi

    cd "$CURDIR/build-cross-$ARCH"
    if test 1 != $REBUILD || test ! -e Makefile; then
        ../mono/configure --prefix="$CURDIR/build-cross-$ARCH-install" --build=$BUILD --target=$MINGW --host=$MINGW --with-tls=none --disable-mcs-build --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG=false mono_cv_clang=no || exit 1
        sed -e 's/-lgcc_s//' -i libtool
    fi
    WINEPREFIX=/dev/null make $MAKEOPTS || exit 1
    rm -rf "$CURDIR/build-cross-$ARCH-install"
    make install || exit 1
    cd "$CURDIR"

    mkdir -p "$CURDIR/image/bin"
    cp "$CURDIR/build-cross-$ARCH-install/bin/libmono-2.0.dll" "$CURDIR/image/bin/libmono-2.0-$ARCH.dll"
}

build_cli ()
{
    # build mono
    if test 1 != $REBUILD; then
        rm -rf "$CURDIR/build-cross-cli"
    fi

    if test ! -d "$CURDIR/build-cross-cli"; then
        mkdir "$CURDIR/build-cross-cli"
    fi

    cd "$CURDIR/build-cross-cli"
    if test 1 != $REBUILD || test ! -e Makefile; then
        ../mono/configure --prefix="$CURDIR/build-cross-cli-install" --with-mcs-docs=no --disable-system-aot || exit 1
    fi
    make $MAKEOPTS || exit 1
    rm -rf "$CURDIR/build-cross-cli-install"
    make install || exit 1
    cd "$CURDIR"

    # set up for further builds
    export PATH="$CURDIR/build-cross-cli-install/bin":$PATH
    export LD_LIBRARY_PATH="$CURDIR/build-cross-cli-install/lib":$LD_LIBRARY_PATH
    export MONO_GAC_PREFIX="$CURDIR/build-cross-cli-install"

    # build mono-basic
    cd "$CURDIR/mono-basic"
    ./configure --prefix="$CURDIR/build-cross-cli-install" || exit 1
    make $MAKEOPTS || exit 1
    make install || exit 1
    cd "$CURDIR"

    # build image/ directory
    mkdir -p "$CURDIR/image/lib"
    cp -r "$CURDIR/build-cross-cli-install/etc" "$CURDIR/image/"
    cp -r "$CURDIR/build-cross-cli-install/lib/mono" "$CURDIR/image/lib"

    cp "$CURDIR/build-cross-cli-install/etc/mono/2.0/machine.config" "$CURDIR/image/1.1-machine.config"
    cp "$CURDIR/build-cross-cli-install/etc/mono/2.0/machine.config" "$CURDIR/image/2.0-machine.config"
    cp "$CURDIR/build-cross-cli-install/etc/mono/4.0/machine.config" "$CURDIR/image/4.0-machine.config"

    # remove debug files
    for f in `find image|grep '\.mdb$'`; do
        rm "$f"
    done
}

build_directorytable ()
{
    echo 'Directory\tDirectory_Parent\tDefaultDir'
    echo 's72\tS72\tl255'
    echo 'Directory\tDirectory'

    echo 'TARGETDIR\t\tSourceDir'
    echo 'MONODIR\tMONOBASEDIR\tmono-2.0:.'
    echo 'MONOBASEDIR\tWindowsFolder\tmono:.'
    echo 'WindowsFolder\tTARGETDIR\t.'
    echo 'WindowsDotNet\tWindowsFolder\tMicrosoft.NET'
    echo 'WindowsDotNetFramework\tWindowsDotNet\tFramework'
    echo 'WindowsDotNetFramework11\tWindowsDotNetFramework\tv1.1.4322'
    echo 'WindowsDotNetFramework11Config\tWindowsDotNetFramework11\tCONFIG'
    echo 'WindowsDotNetFramework20\tWindowsDotNetFramework\tv2.0.50727'
    echo 'WindowsDotNetFramework20Config\tWindowsDotNetFramework20\tCONFIG'
    echo 'WindowsDotNetFramework30\tWindowsDotNetFramework\tv3.0'
    echo 'WindowsDotNetFramework30wcf\tWindowsDotNetFramework30\twindows communication foundation'
    echo 'WindowsDotNetFramework30wpf\tWindowsDotNetFramework30\twpf'
    echo 'WindowsDotNetFramework40\tWindowsDotNetFramework\tv4.0.30319'
    echo 'WindowsDotNetFramework40Config\tWindowsDotNetFramework40\tCONFIG'

    cd "$CURDIR/image"

    for f in `find -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        KEY=`echo $f|sed -e 's/\//|/g'`
        DIRNAME=`dirname $f|sed -e 's/\//|/g'`
        if test x. = x$DIRNAME; then
            DIRNAME=MONODIR
        fi
        BASENAME=`basename $f`
        echo $KEY\\t$DIRNAME\\t$BASENAME
    done

    cd "$CURDIR"
}

build_componenttable ()
{
    echo 'Component\tComponentId\tDirectory_\tAttributes\tCondition\tKeyPath'
    echo 's72\tS38\ts72\ti2\tS255\tS72'
    echo 'Component\tComponent'

    echo 'mono-registry\t{93BE4304-497C-4ACB-A0FD-1C3695C011B4}\tWindowsDotNetFramework\t4\t\tDotNetFrameworkInstallRoot'
    echo 'config-1.1\t{0DA29B5A-2050-4200-92EE-442D1EE6CF96}\tWindowsDotNetFramework11Config\t0\t\t1.1-machine.config'
    echo 'config-2.0\t{ABB0BF6A-6610-4E45-8194-64D596667621}\tWindowsDotNetFramework20Config\t0\t\t2.0-machine.config'
    echo 'config-4.0\t{511C0294-4504-4FC9-B5A7-E85CCEE95C6B}\tWindowsDotNetFramework40Config\t0\t\t4.0-machine.config'
    echo 'dotnet-folder\t{22DCE198-F30F-4E74-AEC6-D089B844A878}\tWindowsDotNet\t0\t\t' # needed to remove the folder

    cd "$CURDIR/image"

    for f in `find -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        KEY=`echo $f|sed -e 's/\//|/g'`
        if test ! -f "$CURDIR/component-guids/${KEY}.guid"; then
            uuidgen | tr [a-z] [A-Z] > $CURDIR/component-guids/${KEY}.guid
        fi
        GUID=`cat "$CURDIR/component-guids/${KEY}.guid"`
        KEYPATH=`find "$f" -type f|sort|head -n 1|sed -e 's/\//!/g'`
        echo $KEY\\t{$GUID}\\t$KEY\\t0\\t\\t$KEYPATH
    done

    cd "$CURDIR"
}

build_featurecomponentstable ()
{
    echo 'Feature_\tComponent_'
    echo 's38\ts72'
    echo 'FeatureComponents\tFeature_\tComponent_'

    echo 'wine_mono\tmono-registry'
    echo 'wine_mono\tconfig-1.1'
    echo 'wine_mono\tconfig-2.0'
    echo 'wine_mono\tconfig-4.0'
    echo 'wine_mono\tdotnet-folder'

    cd "$CURDIR/image"

    for f in `find -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        KEY=`echo $f|sed -e 's/\//|/g'`
        echo wine_mono\\t$KEY
    done

    cd "$CURDIR"
}

build_filetable ()
{
    echo 'File\tComponent_\tFileName\tFileSize\tVersion\tLanguage\tAttributes\tSequence'
    echo 's72\ts72\tl255\ti4\tS72\tS20\tI2\ti2'
    echo 'File\tFile'

    SEQ=0

    cd "$CURDIR/image"

    for f in `find -type f | cut -d '/' -f2- | sort`; do
        SEQ=`expr $SEQ + 1`
        KEY=`echo $f|sed -e 's/\//!/g'`
        FILESIZE=`stat --format=%s $f`

        case $f in 1.1-machine.config)
            COMPONENT=config-1.1
            BASENAME=machine.config
        ;;
        2.0-machine.config)
            COMPONENT=config-2.0
            BASENAME=machine.config
        ;;
        4.0-machine.config)
            COMPONENT=config-4.0
            BASENAME=machine.config
        ;;
        *)
            COMPONENT=`dirname $f|sed -e 's/\//|/g'`
            BASENAME=`basename $f`
        ;;
        esac

        echo $KEY\\t$COMPONENT\\t$BASENAME\\t$FILESIZE\\t\\t\\t\\t$SEQ
    done

    IMAGECAB_SEQ=$SEQ

    cd "$CURDIR"
}

build_mediatable ()
{
    echo 'DiskId\tLastSequence\tDiskPrompt\tCabinet\tVolumeLabel\tSource'
    echo 'i2\ti4\tL64\tS255\tS32\tS72'
    echo 'Media\tDiskId'

    echo 1\\t$IMAGECAB_SEQ\\t\\t#image.cab\\t\\t
}

build_msi ()
{
    rm -rf cab-contents
    rm -f image.cab "${MSIFILENAME}"

    mkdir "$CURDIR/cab-contents"

    cd "$CURDIR/image"

    for f in `find -type f | cut -d '/' -f2-`; do
        KEY=`echo $f|sed -e 's/\//!/g'`
        ln -s "$CURDIR/image/$f" "$CURDIR/cab-contents/$KEY"
    done

    cd "$CURDIR/cab-contents"

    "${WINE}" cabarc -m mszip -r -p N ../image.cab *

    cd "$CURDIR"

    build_directorytable > msi-tables/directory.idt
    build_componenttable > msi-tables/component.idt
    build_featurecomponentstable > msi-tables/featurecomponents.idt
    build_filetable > msi-tables/file.idt
    build_mediatable > msi-tables/media.idt

    "$WINE" winemsibuilder -i "${MSIFILENAME}" msi-tables/*.idt
    "$WINE" winemsibuilder -a "${MSIFILENAME}" image.cab image.cab
}


# build

cd "$CURDIR"/mono

if test 1 != $REBUILD || test ! -e configure; then
    # create configure script and such
    NOCONFIGURE=yes ./autogen.sh || exit 1

    BUILD="`./config.guess`"

    if test -f ./Makefile; then
    rm -rf autom4te.cache
    fi
fi

cd "$CURDIR"

rm -rf image
mkdir image

cross_build_mono "$MINGW_x86_64" x86_64

cross_build_mono "$MINGW_x86" x86

build_cli

mkdir image/support
cp dotnetfakedlls.inf image/support/

build_msi

