#!/bin/sh
# Luis Mondesi < lemsx1@hotmail.com
#
# Prints tcp and udp connections that are listening
# 
netstat -na | egrep -i "(tcp|udp)"
