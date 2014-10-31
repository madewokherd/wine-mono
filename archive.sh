#!/bin/sh

# usage: sh archive.sh tree-ish
# Archives a Git revision with all of its submodules.

recursivearchivefiles ()
{
    # recursivearchivefiles directory prefix tree-ish output-file

    cd "$1"

    echo Archiving: "$1"

    # recurse into submodules
    git ls-tree -r "$3"|grep '^[^ ]* commit'|while read line; do
        if test "x$line" = x; then
            continue
        fi

        obj=`echo "$line"|sed -e 's/^[^ ]* [^ ]* \([^	]*\)	.*$/\1/'`
        filename=`echo "$line"|sed -e 's/^[^ ]* [^ ]* [^	]*	\(.*\)$/\1/'`

        if ! test -e "$1"/"$filename"/.git; then
            echo Missing submodule: "$1"/"$filename"
            continue
        fi

        recursivearchivefiles "$1"/"$filename" "$2""$filename"/ "$obj" "$4"

        cd "$1"
    done

    TEMPFILE=`tempfile`
    git archive --format=tar --prefix="$2" "$3" > $TEMPFILE
    tar Af "$4" "$TEMPFILE"
    rm "$TEMPFILE"
}

OUTPUT_FILE="$PWD/$1.tar"

rm -f "$OUTPUT_FILE"

recursivearchivefiles "$PWD" "$1"/ "$1" "$OUTPUT_FILE"

# add monolite
tar rf "$OUTPUT_FILE" --transform 's:^mono/mcs/class/lib:'"$1"':g' mono/mcs/class/lib/monolite

rm -f "$OUTPUT_FILE.gz"
gzip "$OUTPUT_FILE"

