#!/bin/sh
# Last modified: 2003-Jul-09
# Luis Mondesi < lemsx1@hotmail.com >
# 
# need this command too much...
ps ax | grep -v myproc | grep -v grep | grep  "$1"
