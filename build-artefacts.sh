#!/bin/bash
BIMG="huksley/metabase-build"
METABASE_VERSION=${METABASE_VERSION:=v0.30.1}

set -e
rm -Rf metabase
git clone https://github.com/metabase/metabase
cd metabase
git checkout tags/$METABASE_VERSION

PULLS=${METABASE_PULLS:=7047}
for N in `echo $PULLS`; do
	echo "Applying pull request: $N"
    PURL="https://patch-diff.githubusercontent.com/raw/metabase/metabase/pull/$N.patch"
    curl -L -o pull-$N.patch $PURL
    patch -p1 < pull-$N.patch
done
