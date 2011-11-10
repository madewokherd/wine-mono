#!/bin/bash -e
CURDIR="`pwd`"
MINGW_x86=i386-mingw32msvc
CROSS_DIR_x86=/opt/cross/$MINGW_x86
INSTALL_DESTDIR="$CURDIR"
ORIGINAL_PATH="$PATH"
REBUILD=0

function usage ()
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

pushd . > /dev/null

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


function cross_build_mono ()
{
    local MINGW=$1
    local CROSS_DIR=$2
    local ARCH=$3

    if test 1 != $REBUILD; then
        rm -rf "$CURDIR/build-cross-$ARCH"
    fi

    if [ ! -d "$CURDIR/build-cross-$ARCH" ]; then
        mkdir "$CURDIR/build-cross-$ARCH"
    fi

    cd "$CURDIR/build-cross-$ARCH"
    if test 1 != $REBUILD || test ! -e Makefile; then
        ../mono/configure --prefix="$CURDIR/build-cross-$ARCH-install" --build=$BUILD --target=$MINGW --host=$MINGW --with-tls=none --disable-mcs-build --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG=false || exit 1
    fi
    WINEPREFIX=/dev/null make || exit 1
    rm -rf "$CURDIR/build-cross-$ARCH-install"
    make install || exit 1
    cd "$CURDIR"
}

rm -rf image
mkdir image

cross_build_mono "$MINGW_x86" "$CROSS_DIR_x86" x86

