#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@gmail.com >
# Last modified: 2004-Dec-21
#
# DESCRIPTION: ipv4 network calculations (borrowed from googling)
# USAGE:
# CHANGELOG:
# LICENSE: ___

#
# IPv4 address functions
#

# Compute the subnet address associated to a couple IP/netmask
ipv4_subnet() {
    local ip="$1"
    local netmask="$2"

    # Split quad-dotted addresses into bytes
    # There is no double quote around the back-quoted expression on purpose
    # There is no double quote around $ip and $netmask on purpose
    set -- `IFS='.'; echo $ip $netmask`

    echo $(($1 & $5)).$(($2 & $6)).$(($3 & $7)).$(($4 & $8))
}

# Compute the broadcast address associated to a couple IP/netmask
ipv4_broadcast() {
    local ip="$1"
    local netmask="$2"

    # Split quad-dotted addresses into bytes
    # There is no double quote around the back-quoted expression on purpose
    # There is no double quote around $ip and $netmask on purpose
    set -- `IFS='.'; echo $ip $netmask`

    echo $(($1 | (255 - $5))).$(($2 | (255 - $6))).$(($3 | (255 - $7))).$(($4 | (255 - $8)))
}

# main
ipv4_subnet $1 $2
ipv4_broadcast $1 $2

