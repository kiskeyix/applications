#!/bin/sh
# Last modified: 2002-Nov-16
# Luis Mondesi < lemsx1@hotmail.com >
# 
# need this command too much...
ps -ef | grep -v myproc | grep -v grep | grep -i $1 
