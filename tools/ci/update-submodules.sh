#!/bin/sh

# usage: update-submodules.sh
# Clones submodules and checks out current revision, looking in multiple places.

recursiveupdate ()
{
	# recursiveupdate directory

	cd "$1"

	if ! test -e .gitmodules; then
		# no submodules
		return
	fi

	git config -l --file .gitmodules|grep '\.url='|while read line; do
        if test "x$line" = x; then
            continue
        fi

		key=`echo "$line"|sed -e 's/^submodule\.//'|sed -e 's/\.url=.*//'`
		path=$(git config --file .gitmodules submodule."$key".path)
		url=$(git config --file .gitmodules submodule."$key".url)
		urlbase=$(basename "$url")
		commit=$(git rev-parse HEAD:"$path")
		fullpath="$1"/"$path"

		git config --global --add safe.directory "$fullpath"
		
		if ! test -e "$fullpath"/.git; then
			# try the simple way first
			git submodule update --init "$path"
		fi
		
		if ! test -e "$fullpath"/.git; then
			# if we have an absolute url in gitmodules, try that
			if ! case "$url" in ../*) true;; *) false;; esac; then
				git clone "$url" "$fullpath"
			fi
		fi
		
		if ! test -e "$fullpath"/.git; then
			# Try the mono organization
			git clone https://gitlab.winehq.org/mono/"$urlbase" "$fullpath"
		fi
		
		if test ! -e "$fullpath"/.git -a x != x$CI_MERGE_REQUEST_SOURCE_PROJECT_URL; then
			# Try a sibling of the MR source
			git clone "$(dirname "$CI_MERGE_REQUEST_SOURCE_PROJECT_URL")"/"$urlbase" "$fullpath"
		fi

		if test ! -e "$fullpath"/.git; then
			echo "Unable to clone $fullpath"
			exit 1
		fi

		cd "$fullpath"

		if test x"$(git rev-parse HEAD)" != x"$commit"; then
			echo Checking out $commit in $fullpath
			git checkout -f $commit
		fi

		if test x"$(git rev-parse HEAD)" != x"$commit"; then
			git fetch origin "$commit" ||
				git fetch "$url" "$commit" ||
				git fetch https://gitlab.winehq.org/mono/"$urlbase" "$commit" ||
				git fetch "$(dirname "$CI_MERGE_REQUEST_SOURCE_PROJECT_URL")"/"$urlbase" "$commit" ||
				(echo Unable to fetch commit "$commit" in "$fullpath"; exit 1)
			git checkout -f $commit || exit 1
		fi

        recursiveupdate "$fullpath"

        cd "$1"
    done
}

recursiveupdate "$PWD"
