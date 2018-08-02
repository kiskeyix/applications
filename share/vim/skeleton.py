#!/usr/bin/env python

'''
$Revision: 1.0.0 $
$Date: 2018-08-01 22:35 EDT $
my_name < email@example.com >

DESCRIPTION: Python 2.7 and above ... 
USAGE: skeleton --help
LICENSE: ___

Example: python skeleton.py 1 2 --required foo --sum --move paper

'''

import argparse
import sys

parser = argparse.ArgumentParser(description='description for skeleton program to ...')
                    # ... usage='skeleton [options]')
parser.add_argument('integers', metavar='N', type=int, nargs='+',
                    help='an integer for the accumulator')
parser.add_argument('--sum', dest='accumulate', action='store_const',
                    const=sum, default=max,
                    help='sum the integers (default: find the max)')

parser.add_argument('--move', choices=['rock', 'paper', 'scissors'])
parser.add_argument('--required', required=True)

try:
    args = parser.parse_args()
    print args.accumulate(args.integers)
#except BaseException as e:
except Exception as e:
    print "ERROR: typical error %s\n" % str(e)
    print sys.exc_type
    print sys.exc_info
    print sys.exc_traceback
