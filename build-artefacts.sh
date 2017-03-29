#!/bin/bash
set -e

git clone https://github.com/metabase/metabase
cd metabase
git checkout tags/v0.23.0

PULLS="4405"
for N in `echo $PULLS`; do
	echo "Applying pull request: $N"
    PURL="https://patch-diff.githubusercontent.com/raw/metabase/metabase/pull/$N.patch"
    curl -L -o pull-$N.patch $PURL
    patch -p1 < pull-$N.patch
done

BIMG="huksley/metabase-build"
RIMG="huksley/metabase"

PREV=`docker images $BIMG -q`
if [ "$PREV" != "" ]; then
	echo "Removing previous image $PREV"
	docker rmi $PREV
fi

echo "Building compilation container..."
docker build --tag $BIMG .

echo "Getting files from container"
CID=`docker create $BIMG`
docker copy $CID:/app/source/bin/start ../start
docker copy $CID:/app/source/target/uberjar/metabase.jar ../metabase.jar
docker rm $CID

echo "Building real container image"
cd ..

PREV=`docker images $RIMG -q`
if [ "$PREV" != "" ]; then
	echo "Removing previous image $PREV"
	docker rmi $PREV
fi

echo "Building running container..."
docker build --tag $RIMG .
