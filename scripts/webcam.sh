#!/bin/bash
# copy my ~/webcam.jpg image to my webserver every
# SLEEPTIME seconds :-D
# 
SLEEPTIME=30;

while [ 1 ]; do
    scp ~/webcam.jpg luigi@66.9.192.29:latinomixed.com/html/lems1/webcam/ 2>&1 > /dev/null ;
    sleep $SLEEPTIME;
done
