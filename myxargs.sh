#!/bin/bash
# look for $1 in all regular files found by 'find'
find . -name \* -type f | xargs grep -si "$1"

