#!/bin/sh
#
# cosmo/buildAPPerl.sh - Builds Actually Portable Perl from a
# cosmopolitan build of perl
#
# Run this from the root of the perl repo, see README.cosmo

set -eux

# check environment
#   perl.com should exist after make
#   (THIS MUST BE UNRUN AS IT CURRENTLY IS SELF MODIFYING)
if [ ! -f "$PERL_APE" ]; then
    echo "<<<buildAPPerl>>> perl ape not found"
    exit 1
fi

# setup output directories
if [ -d "$OUTPUTDIR" ]; then
    rm -rf "$OUTPUTDIR"
fi
mkdir -p "$OUTPUTDIR"
TEMPDIR="$OUTPUTDIR/tmp"
mkdir -p "$TEMPDIR"

# get the prefix
PERL_PREFIX=$(./perl -Ilib -e 'use Config; print $Config{prefix}')
PREFIX_NOZIP=$(echo -n "$PERL_PREFIX" | sed 's&^/zip/*&&')
[ "$PREFIX_NOZIP" = '' ] || PREFIX_NOZIP="$PREFIX_NOZIP/"
echo "<<<buildAPPerl>>> prefix: $PERL_PREFIX nozip: $PREFIX_NOZIP"

# get the version
PERL_VERSION=$(./perl -Ilib -e 'use Config; print $Config{version}')

# build the folder structure
make "DESTDIR=$TEMPDIR" install

# remove not actually portable perl
rm "$TEMPDIR$PERL_PREFIX/bin/perl" "$TEMPDIR$PERL_PREFIX/bin/perl$PERL_VERSION"

# copy in perl.com
APPNAME=$(basename "$PERL_APE")
APPPATH="$TEMPDIR/$APPNAME"
cp "$PERL_APE" "$APPPATH"
chmod u+w "$APPPATH"

# finally add the files to zip
THIS_DIR=$(realpath .)
ZIP_ROOT="$TEMPDIR/zip"
cd "$ZIP_ROOT"
zip -r "$APPPATH" "$PREFIX_NOZIP"lib "$PREFIX_NOZIP"bin
cd "$THIS_DIR"

# success, move perl.com out of temp
mv $APPPATH "$OUTPUTDIR/perl.com"
