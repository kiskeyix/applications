#!/bin/sh
# $Revision: 1.2 $
# Luis Mondesi < lemsx1@hotmail.com
# Use Vim as a PAGER, behaves like less
cat $1 \
| col -b \
| vim -c 'se ft=man ro nomod wrap ls=1 notitle ic' \
-c 'set nu!' \
-c 'nmap q :q!<CR>' -c 'nmap <Space> <C-F>' -c 'nmap b <C-B>' \
-c 'nmap f <C-F>' -c 'norm L' -

