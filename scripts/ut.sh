#!/bin/sh
# 
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: date
#
# Wrapper for Unreal Tournament
# Basically, it uses mutt's alias
# 'unreal' from my .muttrc or .alias file
# and then it sends a message to my buddies
# whenever I start the UT sever
#

MESSAGE="Let's rock! \n Estoy en vicio en Unreal Tournament. Si quieren jugar, vayan a mi servidor: lems.homeip.net. \n Ya saben la clave. Si se te olvidó, entonces mándame un mensaje a mi email..."

echo -e ${MESSAGE} | mutt unreal
sleep 5
/usr/local/games/ut/ut

