#!/bin/bash

FILES=`find . -name "$1"`;

for i in $FILES; do
    cvs add $i;
done
