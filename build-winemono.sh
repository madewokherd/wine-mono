#!/bin/sh
CURDIR="`pwd`"
MINGW_x86=i386-mingw32msvc
CROSS_DIR_x86=/opt/cross/$MINGW_x86
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

 -d DIR     Sets the location of directory where x86 MINGW is installed [$CROSS_DIR_x86]
 -m MINGW   Sets the x86 MINGW target name to be passed to configure [$MINGW_x86]
 -t         Build the mono test suite
 -r         Rebuild (skips configure)
EOF

    exit 1
}

while getopts "d:m:trh" opt; do
    case "$opt" in
	d) CROSS_DIR_x86="$OPTARG" ;;
	m) MINGW_x86="$OPTARG" ;;
	t) BUILD_TESTS=1 ;;
	r) REBUILD=1 ;;
	*) usage ;;
    esac
done


# create configure script and such
cd "$CURDIR"/mono

if test 1 != $REBUILD || test ! -e configure; then
    NOCONFIGURE=yes ./autogen.sh || exit 1

    BUILD="`./config.guess`"

    if test -f ./Makefile; then
    rm -rf autom4te.cache
    fi
fi

cd "$CURDIR"


cross_build_mono ()
{
    local MINGW=$1
    local CROSS_DIR=$2
    local ARCH=$3

    if test 1 != $REBUILD; then
        rm -rf "$CURDIR/build-cross-$ARCH"
    fi

    if test ! -d "$CURDIR/build-cross-$ARCH"; then
        mkdir "$CURDIR/build-cross-$ARCH"
    fi

    cd "$CURDIR/build-cross-$ARCH"
    if test 1 != $REBUILD || test ! -e Makefile; then
        ../mono/configure --prefix="$CURDIR/build-cross-$ARCH-install" --build=$BUILD --target=$MINGW --host=$MINGW --with-tls=none --disable-mcs-build --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG=false mono_cv_clang=no || exit 1
    fi
    WINEPREFIX=/dev/null make || exit 1
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
    make || exit 1
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
    make || exit 1
    make install || exit 1
    cd "$CURDIR"

    # build image/ directory
    mkdir -p "$CURDIR/image/lib"
    cp -r "$CURDIR/build-cross-cli-install/etc" "$CURDIR/image/"
    cp -r "$CURDIR/build-cross-cli-install/lib/mono" "$CURDIR/image/lib"

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

    echo 'mono\t{ACFBD087-C2FF-432A-AD88-9927F7C33901}\tMONODIR\t0\t\t'

    cd "$CURDIR/image"

    for f in `find -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        KEY=`echo $f|sed -e 's/\//|/g'`
        GUID=`uuidgen | tr [a-z] [A-Z]`
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

    echo 'wine_mono\tmono'

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

    for f in `find -type f | cut -d '/' -f2-`; do
        SEQ=`expr $SEQ + 1`
        KEY=`echo $f|sed -e 's/\//!/g'`
        FILESIZE=`stat --format=%s $f`
        DIRNAME=`dirname $f|sed -e 's/\//|/g'`
        BASENAME=`basename $f`
        echo $KEY\\t$DIRNAME\\t$BASENAME\\t$FILESIZE\\t\\t\\t\\t$SEQ
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

rm -rf image
mkdir image

cross_build_mono "$MINGW_x86" "$CROSS_DIR_x86" x86

build_cli

build_msi

