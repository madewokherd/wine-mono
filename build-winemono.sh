#!/bin/sh

# setup

CURDIR="`pwd`"
MINGW_x86=i686-w64-mingw32
MINGW_x86_64=x86_64-w64-mingw32
INSTALL_DESTDIR="$CURDIR"
ORIGINAL_PATH="$PATH"
REBUILD=0
WINE=${WINE:-`which wine`}
MSIFILENAME=winemono.msi
BUILD_TESTS=0

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
    # Unset CC, if it is set, otherwise the build scripts will attempt to use the wrong compiler
    unset CC

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
    cd "$CURDIR/build-cross-$ARCH/support"
    WINEPREFIX=/dev/null make $MAKEOPTS || exit 1
    rm -rf "$CURDIR/build-cross-$ARCH-install"
    cd "$CURDIR/build-cross-$ARCH"
    make install || exit 1
    cd "$CURDIR"

    mkdir -p "$CURDIR/image/bin"
    cp "$CURDIR/build-cross-$ARCH-install/bin/libmono-2.0.dll" "$CURDIR/image/bin/libmono-2.0-$ARCH.dll"
    cp "$CURDIR/build-cross-$ARCH/support/.libs/libMonoPosixHelper.dll" "$CURDIR/image/bin/MonoPosixHelper-$ARCH.dll"
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

    # build tests if necessary
    if test x$BUILD_TESTS = x1; then
        for profile in `ls "$CURDIR/mono/mcs/class/lib"`; do
            if test -e "$CURDIR/mono/mcs/class/lib/$profile/nunit-console.exe"; then
                cd "$CURDIR/mono/mcs/class/"
                make $MAKEOPTS -k test PROFILE=$profile

                rm -rf "$CURDIR/tests-$profile"
                mkdir "$CURDIR/tests-$profile"
                cd "$CURDIR/mono/mcs/class"
                cp */*_test_$profile.dll "$CURDIR/tests-$profile"
                
                # System.Drawing test's extra files
                mkdir -p "$CURDIR/tests-$profile/Test/System.Drawing"
                cp -r System.Drawing/Test/System.Drawing/bitmaps "$CURDIR/tests-$profile/Test/System.Drawing"

                cd "$CURDIR/mono/mcs/class/lib/$profile"
                cp nunit* "$CURDIR/tests-$profile"
            fi
        done
    fi

    # set up for further builds
    export PATH="$CURDIR/build-cross-cli-install/bin":$PATH
    export LD_LIBRARY_PATH="$CURDIR/build-cross-cli-install/lib":$LD_LIBRARY_PATH
    export MONO_GAC_PREFIX="$CURDIR/build-cross-cli-install"
    export MONO_CFG_DIR="$CURDIR/build-cross-cli-install/etc"

    # build mono-basic
    cd "$CURDIR/mono-basic"
    ./configure --prefix="$CURDIR/build-cross-cli-install" || exit 1
    make $MAKEOPTS || exit 1
    make install || exit 1

    # build OpenTK
    cd "$CURDIR/opentk"
    xbuild Source/OpenTK/OpenTK.csproj /p:Configuration=Xna4 || exit 1
    cp 'Wine.OpenTK, Version=4.0.0.0.dll' Wine.OpenTK.dll
    gacutil -i Wine.OpenTK.dll
    ln -s "$CURDIR/opentk/Wine.OpenTK, Version=4.0.0.0.dll" "$CURDIR/build-cross-cli-install/lib/mono/4.0/Wine.OpenTK.dll"

    # build MonoGame
    cd "$CURDIR/MonoGame"
    xbuild MonoGame.Framework.Wine.sln /p:Configuration=Release || exit 1
    gacutil -i ThirdParty/Lidgren.Network/bin/Release/Lidgren.Network.Wine.dll || exit 1
    gacutil -i MonoGame.Framework/bin/Release/MonoGame.Framework.Wine.dll || exit 1
    for name in Microsoft.Xna.Framework Microsoft.Xna.Framework.Game Microsoft.Xna.Framework.Graphics Microsoft.Xna.Framework.Xact; do
        sn -R ${name}/bin/Release/${name}.dll ../mono/mcs/class/mono.snk || exit 1
        gacutil -i ${name}/bin/Release/${name}.dll || exit 1
    done

    # build image/ directory
    cd "$CURDIR"
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
    echo 'mono-registry64\t{E088D122-0696-4137-BC4E-C999303B4BE2}\tWindowsDotNetFramework\t360\t\tDotNetFrameworkInstallRoot'
    echo 'config-1.1\t{0DA29B5A-2050-4200-92EE-442D1EE6CF96}\tWindowsDotNetFramework11Config\t0\t\t1.1-machine.config'
    echo 'config-2.0\t{ABB0BF6A-6610-4E45-8194-64D596667621}\tWindowsDotNetFramework20Config\t0\t\t2.0-machine.config'
    echo 'config-4.0\t{511C0294-4504-4FC9-B5A7-E85CCEE95C6B}\tWindowsDotNetFramework40Config\t0\t\t4.0-machine.config'
    echo 'dotnet-folder\t{22DCE198-F30F-4E74-AEC6-D089B844A878}\tWindowsDotNet\t0\t\t' # needed to remove the folder
    echo 'framework-folder\t{41B3A67B-63F4-4491-A53C-9E792BE5A889}\tWindowsDotNetFramework\t0\t\t'
    echo 'framework11-folder\t{20F5741D-4655-400D-8373-7607A84D2478}\tWindowsDotNetFramework11\t0\t\t'
    echo 'framework20-folder\t{B845FD54-09B7-467C-800F-205A142F2F20}\tWindowsDotNetFramework20\t0\t\t'
    echo 'framework30-folder\t{C3221C80-F9D2-41B5-91E1-F6ADBB05ABBC}\tWindowsDotNetFramework30\t0\t\t'
    echo 'framework30wcf-folder\t{1ECAD22C-31C2-4BAC-AC74-78883C396FAB}\tWindowsDotNetFramework30wcf\t0\t\t'
    echo 'framework30wpf-folder\t{3C146462-0CAF-4F07-83E6-A75A2A5DE961}\tWindowsDotNetFramework30wpf\t0\t\t'
    echo 'framework40-folder\t{29ECF991-3E9E-4D23-B0B2-874631642B13}\tWindowsDotNetFramework40\t0\t\t'
    echo 'monobase-folder\t{BE46D94A-7443-4B5C-9B91-6A83815365AB}\tMONOBASEDIR\t0\t\t'
    echo 'mono-folder\t{FD7F9172-4E35-4DF5-BD6A-FB7B795D9346}\tMONODIR\t0\t\t'

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
        KEYPATH=`find "$f" -maxdepth 1 -type f|sort|head -n 1|sed -e 's/\//!/g'`
        echo $KEY\\t{$GUID}\\t$KEY\\t0\\t\\t$KEYPATH
    done

    cd "$CURDIR"
}

build_createfoldertable ()
{
    echo 'Directory_\tComponent_'
    echo 's72\ts72'
    echo 'CreateFolder\tDirectory_\tComponent_'

    echo 'WindowsDotNet\tdotnet-folder'
    echo 'WindowsDotNetFramework\tframework-folder'
    echo 'WindowsDotNetFramework11\tframework11-folder'
    echo 'WindowsDotNetFramework20\tframework20-folder'
    echo 'WindowsDotNetFramework30\tframework30-folder'
    echo 'WindowsDotNetFramework30wcf\tframework30wcf-folder'
    echo 'WindowsDotNetFramework30wpf\tframework30wpf-folder'
    echo 'WindowsDotNetFramework40\tframework40-folder'
    echo 'MONOBASEDIR\tmonobase-folder'
    echo 'MONODIR\tmono-folder'

    cd "$CURDIR/image"

    for f in `find -type d | cut -d '/' -f2-`; do
        if test x. = x$f; then
            continue
        fi
        FILE=`find "$f" -maxdepth 1 -type f`
        if test ! "$FILE"; then
            KEY=`echo $f|sed -e 's/\//|/g'`
            echo $KEY\\t$KEY
        fi
    done

    cd "$CURDIR"
}

build_featurecomponentstable ()
{
    echo 'Feature_\tComponent_'
    echo 's38\ts72'
    echo 'FeatureComponents\tFeature_\tComponent_'

    echo 'wine_mono\tmono-registry'
    echo 'wine_mono\tmono-registry64'
    echo 'wine_mono\tconfig-1.1'
    echo 'wine_mono\tconfig-2.0'
    echo 'wine_mono\tconfig-4.0'
    echo 'wine_mono\tdotnet-folder'
    echo 'wine_mono\tframework-folder'
    echo 'wine_mono\tframework11-folder'
    echo 'wine_mono\tframework20-folder'
    echo 'wine_mono\tframework30-folder'
    echo 'wine_mono\tframework30wcf-folder'
    echo 'wine_mono\tframework30wpf-folder'
    echo 'wine_mono\tframework40-folder'
    echo 'wine_mono\tmonobase-folder'
    echo 'wine_mono\tmono-folder'

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

hex_to_binary ()
{
    HEXCHAR=`head -c 2|tr [a-f] [A-F]`

    while test x != x"$HEXCHAR"; do
        printf '\'`echo 'ibase=16; obase=8;' $HEXCHAR|bc`
        HEXCHAR=`head -c 2|tr [a-f] [A-F]`
    done
}

format_od_output ()
{
    echo $2'\t'$3'\t'$4'\t'$5'\t'
}

build_msifilehashtable ()
{
    echo 'File_\tOptions\tHashPart1\tHashPart2\tHashPart3\tHashPart4'
    echo 's72\ti2\ti4\ti4\ti4\ti4'
    echo 'MsiFileHash\tFile_'

    cd "$CURDIR/image"

    for f in `find -type f | cut -d '/' -f2- | sort`; do
        KEY=`echo $f|sed -e 's/\//!/g'`
        FILESIZE=`stat --format=%s $f`

        echo -n $KEY\\t0\\t
        if test $FILESIZE -eq 0; then
            echo '0\t0\t0\t0'
        else
            format_od_output `md5sum $f|head -c 32|hex_to_binary|od -v -t d4`
        fi
    done

    cd "$CURDIR"
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
    build_createfoldertable > msi-tables/createfolder.idt
    build_featurecomponentstable > msi-tables/featurecomponents.idt
    build_filetable > msi-tables/file.idt
    build_mediatable > msi-tables/media.idt
    build_msifilehashtable > msi-tables/msifilehash.idt

    "$WINE" winemsibuilder -i "${MSIFILENAME}" msi-tables/*.idt
    "$WINE" winemsibuilder -a "${MSIFILENAME}" image.cab image.cab
}

sanity_checks ()
{
    # Make sure a few programs are around, otherwise we'll fail later on:
    if test ! -x "$WINE"
    then
        echo "You need to have wine installed. You can set the path to it with WINE=/path/to/wine"
        exit 1
    fi

    if test ! -x "`which gmcs 2>/dev/null`"
    then
        echo "You need to have gmcs from mono installed."
        exit 1
    fi
}

# build

sanity_checks

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

