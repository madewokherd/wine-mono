#!/bin/sh
CURDIR="`pwd`"
MINGW_x86=i386-mingw32msvc
CROSS_DIR_x86=/opt/cross/$MINGW_x86
INSTALL_DESTDIR="$CURDIR"
ORIGINAL_PATH="$PATH"
REBUILD=0

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

    mkdir -p "$CURDIR/image/lib"
    cp -r "$CURDIR/build-cross-cli-install/etc" "$CURDIR/image/"
    cp -r "$CURDIR/build-cross-cli-install/lib/mono" "$CURDIR/image/lib"
}

rm -rf image
mkdir image

cross_build_mono "$MINGW_x86" "$CROSS_DIR_x86" x86

build_cli

