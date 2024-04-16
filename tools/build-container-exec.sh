#!/bin/sh

SRCDIR=$(realpath "$(dirname "$(realpath "$0")")/..")

mkdir -p "${SRCDIR}/build/podman-home"

exec podman run -u root -t --init -a stdin -a stdout -a stderr --volume "${SRCDIR}:/var/hostdir:Z" --volume "${SRCDIR}/build/podman-home:/root:Z" -w /var/hostdir --read-only wine-mono-build "$@"

