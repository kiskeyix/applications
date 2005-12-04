#!/bin/sh
# $Revision: 1.6 $
# $Date: 2005-12-04 20:48:29 $
# Luis Mondesi < lemsx1@hotmail.com >
#
# DESCRIPTION: a simple script to write VCD .cue files
# USAGE: run from current directory. pass .cue file
#       write_vcd.sh file.cue
# CHANGELOG:
# LICENSE: GPL
#

# device block:
#DEV=/dev/dvd
DEV=ATA:1,0,0
cdrdao write --device $DEV --driver generic-mmc $@ && eject
