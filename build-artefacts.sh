#!/bin/bash
BIMG="huksley/metabase-build"
METABASE_VERSION="v0.23.0"

set -e
rm -Rf metabase
git clone https://github.com/metabase/metabase
cd metabase
git checkout tags/$METABASE_VERSION

PULLS="4405"
for N in `echo $PULLS`; do
	echo "Applying pull request: $N"
    PURL="https://patch-diff.githubusercontent.com/raw/metabase/metabase/pull/$N.patch"
    curl -L -o pull-$N.patch $PURL
    patch -p1 < pull-$N.patch
done

PREV=`docker images $BIMG -q`
if [ "$PREV" != "" ]; then
	echo "Removing previous image $PREV"
	docker rmi $PREV
fi

echo "Building compilation container..."
docker build --tag $BIMG .

echo "Getting files from container"
CID=`docker create $BIMG`
docker cp $CID:/app/source/bin/start ../start
docker cp $CID:/app/source/target/uberjar/metabase.jar ../metabase.jar
docker rm $CID
