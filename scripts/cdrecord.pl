#!/usr/bin/perl -w
# a quick nautilus script to burn isos... 
# Just select the iso you want and choose this script
# from the nautilus script menu.

`cdrecord $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"} >  cdrecord.log`;
