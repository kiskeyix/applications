#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Jan-22
#
# DESCRIPTION:
# USAGE:
# CHANGELOG:
#

case $1 in
    configure)
    #    ./configure \
    #    -D EAPI \
    #    -D HAVE_MMAP \
    #    -D HAVE_SHMGET\
    #    -D USE_SHMGET_SCOREBOARD\
    #    -D USE_MMAP_FILES\
    #    -D HAVE_FCNTL_SERIALIZED_ACCEPT\
    #    -D HAVE_SYSVSEM_SERIALIZED_ACCEPT\
    #    -D SINGLE_LISTEN_UNSERIALIZED_ACCEPT\
    #    -D DYNAMIC_MODULE_LIMIT=64\
    #    -D HARD_SERVER_LIMIT=4096\
    #    -D HTTPD_ROOT="/usr"\
    #    -D SUEXEC_BIN="/usr/lib/apache/suexec"\
    #    -D DEFAULT_PIDLOG="/var/run/apache.pid"\
    #    -D DEFAULT_SCOREBOARD="/var/run/apache.scoreboard"\
    #    -D DEFAULT_LOCKFILE="/var/run/apache.lock"\
    #    -D DEFAULT_ERRORLOG="/var/log/apache/error.log"\
    #    -D TYPES_CONFIG_FILE="/etc/mime.types"\
    #    -D SERVER_CONFIG_FILE="/etc/apache/httpd.conf"\
    #    -D ACCESS_CONFIG_FILE="/etc/apache/httpd.conf"\
    #    -D RESOURCE_CONFIG_FILE="/etc/apache/httpd.conf"\

    ./configure --prefix=/usr/local \
    --enable-module=so \
    --sysconfigdir=/etc/apache

    ;;

    make)
    make && sudo make install
    ;;

    php-configure)
    ./configure --prefix=/usr/local \
    --with-config-file-path=/etc/php4/apache \
    --with-mysql=/usr \
    --with-apxs=/usr/local/bin/apxs

    ;;

esac

