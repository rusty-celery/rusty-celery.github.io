#!/bin/bash

set -e
exitcode=0

md_files=$(find src -name '*.md')
for f in $md_files; do
    short="${f:4}"
    if grep -Fq "$short" ./src/lib.rs
    then
        echo "$short ok"
    else
        echo "$short missing from ./src/lib.rs"
        exitcode=1
    fi
done

exit $exitcode
