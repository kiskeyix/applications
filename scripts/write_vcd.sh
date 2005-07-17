#!/bin/sh
# $Revision: 1.5 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Aug-19
#
# DESCRIPTION: a simple script to write VCD .cue files
# USAGE: run from current directory. pass .cue file
#       write_vcd.sh file.cue
# CHANGELOG:
#

# device block:
#DEV=/dev/dvd
DEV=ATA:1,0,0
cdrdao write --device $DEV --driver generic-mmc $@ && eject
