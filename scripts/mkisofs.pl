#!/usr/bin/perl -w
# a quick nautilus script to make isos... 
# Just select the directory you want and choose this script
# from the nautilus script menu.

# removes end-lines and put a .iso extension
( $name = $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"} ) =~ s,\n,.iso,g;
`mkisofs -J -r -v -o "$name" $ENV{"NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"}`;
