#!/bin/sh

# usage: sh archive.sh tree-ish

recursivearchivefiles ()
{
    # recursivearchivefiles directory prefix tree-ish output-file
    cd "$1"
    for f in `git ls-files`; do
        if test -d "$f/.git"; then
            recursivearchivefiles "$PWD"/"$f" "$2""$f"/ "`git rev-parse HEAD:$f`" "$4"
            cd "$1"
        fi
    done

    TEMPFILE=`tempfile`
    git archive --format=tar --prefix="$2" "$3" > $TEMPFILE
    tar Af "$4" "$TEMPFILE"
    rm "$TEMPFILE"
}

OUTPUT_FILE="$PWD/$1.tar"

rm "$OUTPUT_FILE"

recursivearchivefiles "$PWD" "$1"/ "$1" "$OUTPUT_FILE"

gzip "$OUTPUT_FILE"

