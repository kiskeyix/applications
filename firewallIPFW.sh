#!/bin/sh
#
# Luis Mondesi for latinomixed.com
# lemsx1@hotmail.com
#
# DESCRIPTION:
# This scripts sets up a firewall using 'ipfw' (the free firewall
# included with MacOS X from version 10.0.4 and up I believe).
# To 'install' it just make a directory in /System/Library/StartupItems
# named 'myIPFW' (sudo mkdir /System/Library/StartupItems/myIPFW) 
# and put this script plus the myIPFW shell script and the
# StartupParameters.plist there. These files are basically composed of:
# -- myIPFW --
##!/bin/sh 
# . /etc/rc.common
# # this path can be changed to anything you want, read myIPFW for more
# ConsoleMessage "Starting Firewall with /System/Library/StartupItems/myIPFW/firewallIPFW.sh"
#/System/Library/StartupItems/myIPFW/firewallIPFW.sh
# -- end myIPFW --
#
# and
#
# -- StartupParameters.plist
#{
#         Description = "Firewall startup";
#         Requires = ("Network");
#         OrderPreference = "None";
#         Messages = { start = "Starting Firewall"; stop = "Stopping Firewall"; };
#}
#
# DISTRIBUTION:
# As everything we do in LatinoMixed.com, this is licensed
# using GPL (copyleft). So feel free to distribute this code
# for as long as these notes are preserved. 
# DISCLAIMER:
# Use this script at your own risk! No warranties whatsoever ...
#
# It has been tested and it works fine though
#
# NOTES:
# interfaces on the MacOS X platform are named:
# en# for ethernet 
# ppp# for ppp connections (dialup and PPPoE -- DSL)
# e.g. ethernet card number one will be: en0
# ppp connection one will be: ppp0
# you can use wildcard *. e.g. to match all ppp* or all en*
#
# Anything starting with '#' is considered to be a commment
#
# let's start:
#forget all we know
ipfw -f flush

# this line will divert port 8668 (nat) to ppp0
# it slows down the startup of the firewall... comment out
# unless needed:
#ipfw 00994 add divert 8668 ip from any to any via ppp0

# this line will allow all protocols to get out... dangerous: 
# but needed, you could comment this line out and allow specific
# access to the 'out' port range that you want. Those ports are
# usually listed in /etc/services. Protocols are usually listed in
# /etc/protocols
#ipfw  add allow ip from any to any out
# this is a 'safer' way to allow protocols out:
# we will worry about what calls to what services to let thru later
ipfw add allow tcp from any to any out
ipfw add allow udp from any to any out

# respect established connections
ipfw add allow tcp from any to any established

#allow loop back
#note: ip protocol allows all package match: icmp,tcp,etc...
ipfw add allow ip from 127.0.0.1 to any

#allow my personal network using ethernet interface en*
ipfw add allow ip from 10.0.2.0/24 to any in recv en*

#allow DNS to work
ipfw add allow tcp from any 53 to any in recv any
ipfw add allow udp from any 53 to any in recv any

# allow UNIX not priviledge ports to establish connections
ipfw add allow tcp from any 1024-26208 to any in recv any 

# another way of allowing all incoming packages 
#ipfw add allow tcp from any to any in recv ppp*
#ipfw add allow tcp from any to any in recv en*

# These are the privilege ports we allow a connection too 
#permit in from web ports (http): 80, 8080 and 443, etc...
ipfw add allow tcp from any 80 to any in recv any
ipfw add allow tcp from any 8080 to any in recv any
ipfw add allow tcp from any 443 to any in recv any

#allow secure shell (ssh) to other computers to pass the firewall
ipfw add allow tcp from any 22 to any in recv any 

#certain type of ICMP must be allowed if you want to check
#for the status of your connnection or some host. Types are:
# 0  - echo reply
# 3  - destination unreachable
# 11 - time to live exceeded
ipfw add allow icmp from any to any out via any
ipfw add allow icmp from any to any in recv any icmptypes 0,3,11 

#drop these types from reaching us:
#ipfw add deny icmp from any to any in recv any icmptypes 3,11

# to deny the rest from ppp* uncomment the following:
#ipfw add deny icmp from any to any in recv ppp*

# to match any hostname starting with ad* ...
# just kidding! ... i wish it was that simple 
#ipfw add deny tcp from ad* to any in recv ppp*

# deny the rest of the icmp packages. change the any to interface, if needed
# example: ... in recv ppp0
# ipfw add deny icmp from any to any in recv any 

# if my rules dont match anything, then allow DANGEROUS uh?
ipfw add allow tcp from any to any in

# deny the rest of the protocols from any interface 
# note: protocol 'ip' and 'all' are alias:
ipfw add deny all from any to any

