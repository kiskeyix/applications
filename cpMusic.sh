#!/bin/bash
ARG=-Pauvz  # Progress, all, update, verbose, compress(?)
if [ -d $1 ]; then
	rsync -e ssh -Pauvz  --exclude=.* $1/ luigi@66.9.192.63:music
	rsync -e ssh -Pauvz  --exclude=.* luigi@66.9.192.63:music/ $1
fi
