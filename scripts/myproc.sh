#!/bin/sh
ps ax | grep -v myproc | grep -i $1 
