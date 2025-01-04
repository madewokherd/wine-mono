#!/bin/sh

printf 'Wine builtin DLL\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0' | dd if=/dev/stdin of="$1" bs=1 seek=64 count=32 conv=notrunc
