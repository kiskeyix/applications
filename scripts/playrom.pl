#!/usr/bin/perl
my $file=shift;

sub display_error
{
    my $msg = shift;
    # if you don't have zenity installed, try
    # using Xdialog:
    if ( -x "/usr/bin/zenity" )
    {
        system("zenity --error --text='$msg'");
    } else {
        # FIXME this might be wrong arguments...
        system("Xdialog --error --text='$msg'");
    }
}

if ( $file =~ m/\.nes$/i )
{
    # LEGEND:
    # -fs 1/0 fullscreen (slow machines need opengl off)
    # -opengl 0 turns opengl off
    # -input1 gamepad (use gamepad style)
    # -inputcfg gamepad1 (configures gamepad. do this from the command line)
    system("fceu -fs 1 -input1 gamepad '$file'");
    #system("fceu-sdl '$file'");
    if ( $? != 0 ) 
    {
        display_error("Fceu could not open '$file'");
    }
} else {
    system("zsnes '$file'");
    if ( $? != 0 ) 
    {
        display_error("Znes could not open '$file'");
    }
}
