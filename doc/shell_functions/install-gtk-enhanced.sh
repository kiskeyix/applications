#!/bin/bash

# Check for existing GTK+ 2.2
echo -n "Checking for an existing GTK+ 2.2 installation..."
version=`pkg-config --modversion gtk+-2.0`
if test "$version" = ""; then
	echo " not found."
	echo "GTK+ 2.2 is not installed. This script is meant to upgrade an existing GTK+ 2.2 installation, not to install it from scratch."
	exit 1
else
	is22=$(echo "$version" | awk '{if ($1 >= 2.2) print "yes"; else print "no"}')
	if test "$is22" = "no"; then
		echo " not found."
		echo "GTK+ 2.2 is not installed. This script is meant to upgrade an existing GTK+ 2.2 installation, not an earlier version."
		exit 1
	else
		prefix=`pkg-config --variable=prefix gtk+-2.0`
		echo "found ($prefix)."
	fi
fi


# Now check whether we have to download it

MD5SUM=605332199533e73bc6eec481fb4f1671
ARCHIVENAME=gtk+-2.2.4
ARCHIVE=$ARCHIVENAME.tar.bz2
URL=ftp://ftp.gtk.org/pub/gtk/v2.2/$ARCHIVE


download()
{
	if ! command -v wget >/dev/null 2>/dev/null; then
		echo "The command 'wget' is not found. wget is required to automatically download $1."
		echo "Please either install wget, or download $1 manually from: $2"
		echo "After doing either of those two things, run this script again."
		exit 1
	fi
	wget -c "$2" || exit 1
}

if test -f $ARCHIVE; then
	echo "$ARCHIVE already exists."
	echo -n "Checking for archive integrity..."
	mysum=$(md5sum $ARCHIVE | awk '{print $1}') || exit 1
	if test "$mysum" = "$MD5SUM"; then
		echo " passed."
	else
		echo " failed."
		download "GTK+ 2.2" "$URL"
	fi
else
	download "GTK+ 2.2" "$URL"
fi


# Download the patches
if test "$SKIPPATCH" != "1"; then
	test -f gtkfilesel.patch || download "the file selector patch" "http://members1.chello.nl/~h.lai/gtkenhancements/gtkfilesel.patch"
fi


# Extract the archive
echo -n "Extracting $ARCHIVE..."
if test "$SKIPEXTRACT" != "1"; then
	bzip2 -dc $ARCHIVE | tar -x
	test "$?" != 0 && exit 1
fi
echo " done."


# Apply the patches
cd $ARCHIVENAME
echo
echo -n "Patching the source code..."
if test "$SKIPPATCH" != "1"; then
	patch -s -p1 < ../gtkfilesel.patch || exit 1
	#patch -s -p1 < ../gtktoolbar.patch || exit 1
fi
echo " done."


# Compile
echo
echo "Now compiling GTK+ 2.2:"
echo "./configure --prefix=$prefix"
if test "$SKIPCOMPILE" != "1"; then
	./configure --prefix="$prefix" || exit 1
	make || exit 1
fi
echo "Compilation finished."
echo


haveWriteAccess()
{
	# Does $1 exist?  
	if [[ -d "$1" ]]; then
		# Yes; do we have acess(1) installed?
		if command -v access > /dev/null 2> /dev/null; then
			access -rw "$1"
			return $?
		else
			# No; try to create a temp file in that dir.

			(( i = $$ / $RANDOM + ($RANDOM / 2) ))
			TEMPFILE="$1/apkg-$RANDOM-$$.$i"
			if touch "$TEMPFILE" 2> /dev/null; then
				# Success; remove temp file
				rm -f "$TEMPFILE"
				return 0
			else
				# Failure
				return 1
			fi
	        fi
	else
		# No; try to create that directory.
		if mkdir -p "$1" 2> /dev/null; then
			# Success; we have write access. Now remove that dir.
			rmdir "$1"
			return 0
		else
			# Failure; no write access
			return 1
		fi
	fi
}


# Ask for password
askpass()
{
	su -c 'make install'
	local exitCode=$?

	if test "$exitCode" = "1"; then
		test "$DEBUG" = "1" && echo "DEBUG: Wrong password entered. Recursing function."
		# Wrong password?
		askpass
	elif test "$exitCode" != "0"; then
		exit 1
	fi
}

if haveWriteAccess "$prefix"; then
	test "$DEBUG" = "1" && echo "DEBUG: Has write access to $prefix."
	make install || exit 1
else
	test "$DEBUG" = "1" && echo "DEBUG: No write access to $prefix; installing as root."
	askpass
fi

echo
echo "Installation complete."
echo

read -p "Remove the source code? (y/n) [y] "
test "$REPLY" = "" && REPLY=y
if test "$REPLY" = "y"; then
	rm -rf $ARCHIVENAME
	rm -f $ARCHIVE
	rm -f gtkfilesel.patch gtktoolbar.patch
fi
