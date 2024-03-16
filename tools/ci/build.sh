#!/bin/sh

wget -nv -O wine-build.zip "https://gitlab.winehq.org/wine/wine/-/jobs/artifacts/master/download?job=build-daily-linux" || exit 1
unzip -q wine-build.zip || exit 1

export WINE="$PWD"/usr/local/bin/wine

make "WINE=${WINE:-wine}" -j$(nproc) image tests msi >build.log 2>&1 || exit 1

echo Checking for unnecessary rebuild steps
make "WINE=${WINE:-wine}" -n image
make "WINE=${WINE:-wine}" -q image || exit 127

echo Checking for untracked files
! (git clean -nd|grep .) || exit 127

