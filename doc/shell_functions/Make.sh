#!/bin/sh

case "$1" in
    all)
    echo "Read this file first"
    ;;

    pixdir2html)
    echo "Making pixdir2html release"
    tar czvf pixdir2html.tar.gz \
    --exclude=CVS \
    --exclude=*.bak \
    --exclude=.cvsignore \
    pixdir2html
    ;;

    clean)
    echo "This does nothing"
    ;;

    *)
    echo "Making $1.tar.gz tarball"
    test -d $1 && \
    tar czvf $1.tar.gz \
    --exclude=CVS \
    --exclude=*.bak \
    --exclude=.cvsignore \
    $1
    ;;
esac

