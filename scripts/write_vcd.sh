#!/bin/sh
# $Revision: 1.1 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2004-Jul-23
#
# DESCRIPTION: a simple script to write VCD .cue files
# USAGE: run from current directory. pass .cue file
#       write_vcd.sh file.cue
# CHANGELOG:
#

# device block:
DEV=/dev/dvd

cdrdao write --device $DEV --driver generic-mmc $@
