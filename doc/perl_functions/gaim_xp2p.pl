#!/usr/bin/perl -w
# $Revision: 1.6 $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2003-Oct-12
#
# Xtended Peer 2 Peer
#
# NOTE: this will freeze users computers, or crash their IM.
# Be polite! :-) Gaim does not get overloaded, but don't
# send a huge limit or gaim will freeze... Note that 
# your peer's bandwith will suffer too.
# 
# The main purpose of this script is to bother people
# if you don't want to bother them, then don't use this....
#
# usage: write in a IM window (one to one. no chats yet)
#   
#   _r ## or _rand ## or _are ##
#   , sends random number of characters from global LIMIT/2 up to ##
#   NOTE: added _are because r gets substituted by 'are' by default
#
#   _s ## or _xs ##
#   , _s sends random smilies up to ## 
#    and _xs is the extended version of this... more smiles
#    mostly MSN specific though
#
#   _x message,## 
#   , where message is a string that will be repeated ## times
#
#   _z text,##
#   , zig zags text ## number of times
#   
#
# TODO: 
#   - test chat part (hey, I don't chat as often)
#   - modularize code into sub() calls for routines
#
# BUGS:
#   - string gets send at the end with command: _x string,c
#   - _xs and _s now don't display a thing under AIM if the text
#       is formatted (color,bold,size,etc..)
#

use Gaim;

# usefull variables:
$VERSION = "0.0.8";
$NAME = "xp2p";

%PLUGIN_INFO = (
    perl_api_version => 2,
    name             => $NAME,
    version          => $VERSION,
    summary          => "The main purpose of this script is to bother people by sending annoying messages",
    description      => "The main purpose of this script is to bother people by sending annoying messages \n\t- _r ## or _rand ## or _are ##, sends random number of characters from global LIMIT/2 up to ## NOTE: added _are because r gets substituted by 'are' by default \n\t- _s ## or _xs ## , _s sends random smilies up to ## and _xs is the extended version of this... more smiles mostly MSN specific though \n\t- _x message,## , where message is a string that will be repeated ## times \n\t- _z text,## , zig zags text ## number of times",
    author           => "Luis Mondesi",
    url              => "",
    load             => "plugin_load"
);

$LIMIT = 10; # default limit for all text sent

# list of smiles
@smilies = ("C:)",
    "C:-)",
    "O-)",
    ">:)",
    ">:-)",
    ":-o)))",
    ":-O)))",
    "8-|)",
    ":-]",
    ":-)",
    ":-(",
    ";-)",
    ":-P",
    "=-O",
    ":-*",
    ">:o",
    "8-)",
    ":-\$",
    ":-!",
    ":-[",
    "O:-)",
    ":-/",
    ":'(",
    ":-X",
    ":-D");

@msn_smilies = ("(a)",
    "(A)",
    ":-@",
    ":@",
    ":-[",
    ":[",
    "(B)",
    "(b)",
    "(Z)",
    "(z)",
    "(U)",
    "(u)",
    "(@)",
    "(^)",
    "(o)",
    "(O)",
    "(C)",
    "(c)",
    ":'(",
    ":`(",
    "(W)",
    "(w)",
    "(6)",
    "(&)",
    "(D)",
    "(d)",
    "(E)",
    "(e)",
    "(~)",
    "(F)",
    "(f)",
    "(G)",
    "(g)",
    "(X)",
    "(x)",
    "(%)",
    "(L)",
    "(l)",
    "(H)",
    "(h)",
    "(M)",
    "(m)",
    "(I)",
    "(i)",
    "(K)",
    "(k)",
    ":-D",
    ":D",
    ":-d",
    ":d",
    ":->",
    ":>",
    ":-|",
    ":|",
    "(8)",
    ":-O",
    ":O",
    ":-o",
    ":o",
    "(T)",
    "(t)",
    "(P)",
    "(p)",
    "(?)",
    "(r)",
    "(R)",
    "({)",
    "(})",
    ":-(",
    ":(",
    ":-<",
    "(S)",
    "(s)",
    ":-)",
    ":)",
    "(*)",
    "(#)",
    "(N)",
    "(n)",
    "(Y)",
    "(y)",
    ":-P",
    ":P",
    ":-p",
    ":p",
    ":-S",
    ":S",
    ":-s",
    ":s",
    ";-)",
    ";)",
    ":S-",
    ":-\$",
    ":\$");

# list of characters
@chars = qw/1 2 3 4 5 6 7 8 9 0 ! @ $ % ^ & * ( ) _ + = ` ~ a b c d e f g h i j k l m n o p q r s t u v w x y z < > ? [ ] { } " ' : ; | /;

sub plugin_init 
{
    return %PLUGIN_INFO;
}

sub plugin_load
{
    Gaim::debug_info("$NAME plugin", "plugin_load\n");
    
    $plugin = shift;

    Gaim::signal_connect(
        Gaim::Conversation::handle(),
        "sent-im-msg", 
        $plugin,
        \&xtext_user,
        $NAME
    );

#    Gaim::signal_connect(
#        Gaim::Conversation::handle, 
#        "sending-chat-message", 
#        $plugin,
#        \&xchat_user
#    );
}

# main functions
sub xtext_user 
{
    $index = $_[0];
    $who = $_[1];       # sender
    $message = $_[2];
    $flag = $_[3]; 
    $type = $_[4];

    $type = ( $type eq "chat" ) ? "chat" : "im";

    #Various debug prints to show what has been passed in
    Gaim::debug_info ( "\nindex:  ",  $index);
    Gaim::debug_info ( "\nwho:  ",  $who);
    Gaim::debug_info ( "\nmessage:  ",  $message);
    Gaim::debug_info ( "\nflag:  ",  $flag);
    Gaim::debug_info ( "\ntype:  ",  $type);

    @im_array = Gaim::ims(); #get the array of IM's

    #find the correct IM

    for ($i = 0; $i <= $#im_array; $i++)
    {
        if ( Gaim::Conversation::get_name( Gaim::Conversation::IM::get_conversation ( $im_array[$i] ) ) eq $who )
        {
            #  _x string to repeat,##
            if ($message =~ m/.*_x /i) {
               repeate_msg($im_array[$i],$message,$type); 
            } 

            # _s ##
            # sends ## of random smilies
            elsif ($message =~ m/.*_s /i) {
                rand_smiles($im_array[$i],$message,$type,"normal");
            } # end if

            # _xs ##
            # sends ## of random smilies
            elsif ($message =~ m/.*_xs /i) {
                rand_smiles($im_array[$i],$message,$type,"msn");
            }

            # _z string,##
            # zig zags text up to ##
            elsif ($message =~ m/.*_z /i) 
            {
                zip_zag_msg($im_array[$i],$message,$type);
            }

            # _rand ## or _r ##
            # send random stuff up to ##
            elsif ($message =~ m/.*_rand |.*_r |.*_are /i) 
            {
                rand_msg($im_array[$i],$message,$type);
            } # last elsif
            # messages that don't comply go thru automatically
        } # end if $sender
    } # end for $i
} # end xtext_user

sub xchat_user 
{
    $index = $_[0];
    $who = $_[1]; # sender
    $message = $_[2];
    $flag = $_[3]; 

    # ping pong
    xtext_user($index,$who,$message,$flag,"chat");
}

# helper functions
sub random_int_in ($$) {
    my($min, $max) = @_;
    # Assumes that the two arguments are integers themselves!
    return $min if $min == $max;
    ($min, $max) = ($max, $min)  if  $min > $max;
    return $min + int rand(1 + $max - $min);
} # end random # generator

sub repeat_msg
{
    ($im,$message,$type) = @_;
    
    # split text by commas
    ($message,$limit) = split(/,/,$message);

    #clean up message
    $message =~ s/^(.*)_x (.*)$/$1 $2/gi;

    # verify that $limit has digits and not something else
    $limit = ($limit =~ /\d+/) ? $limit : $LIMIT;

    for ($i=0;$i<$limit;$i++){
        if ( $type eq "chat" ) 
        {
            Gaim::Conversation::Chat::send($im, $message);
        } else {
            Gaim::Conversation::IM::send($im, $message);
        }
    } #end for
}

sub rand_smiles
{
    ($im,$message,$type,$smile_type) = @_;
    
    ($limit = $message) =~ s/^(.*)_s[x]* (.*)$/$1 $2/gi;
    $limit = ($limit =~ /\d+/) ? $limit : $LIMIT;

    # reset $message
    $message = "";

    if ( $smile_type ne "normal" )
    {
        # pick random element from global extended array
        for ($i=0;$i<$limit;$i++) 
        {
            $message .= $msn_smilies[rand @msn_smilies]." ";
        }
    } else {
        # pick random element from normal smilies
        for ($i=0;$i<$limit;$i++) {
            $message .= $smilies[rand @smilies]." ";
        }
    }
    if ( $type eq "chat" )
    {
        Gaim::Conversation::Chat::send($im, $message);
    } else {
        Gaim::Conversation::IM::send($im, $message);
    }
}

sub zig_zag_msg
{
    ($im,$message,$type) = @_;
    
    # split text by commas
    ($message,$limit) = split(/,/,$message);

    #clean up message
    $message =~ s/^(.*)_z (.*)$/$1 $2/gi;

    # verify that $limit has digits and not something else
    $limit = ($limit =~ /^\d+$/) ? $limit : $LIMIT;

    $j = 0; # init another counter 

    for ($i=0;$i<$limit;$i++)
    {
        if ( $j % 8 < 4 ) 
        {
            $wspace .= "   "; # add 3 spaces to text
        } else {
            $wspace =~ s/[\s]{3}//o; # remove 3 spaces from text
        }
        $j++;
        if ( $type eq "chat" )
        { 
            Gaim::Conversation::Chat::send($im, $wspace.$message);
        } else {
            Gaim::Conversation::IM::send($im, $wspace.$message);
        }
    } #end for
}

sub rand_msg
{
    # maybe the user would decide to pipe this to get the meaning of
    # life like:
    # print rand_msg() | grep -i "meaning of life"
    # :-)

    ($im,$message,$type) = @_;

    ($limit = $message) =~ s/^(.*)(_rand|_r|_are)(.*)$/$1 $3/gi;

    $limit = ($limit =~ /^\d+$/) ? $limit : $LIMIT;
    $limit = random_int_in(($LIMIT/2),$limit);

    for ($j=0;$j<$limit;$j++) 
    {

        $message = ""; # reset message
        # to make things a little bit more exciting!
        # multiply limit times 8 number of characters
        # but, if this number happens to be greater than
        # 256, then only generate 255 number of chars
        for ($i=0;$i<((($limit*8)<256)? $limit*8 : 255) ;$i++) {
            $message .= $chars[rand @chars];
        } # end i

        if ( $type eq "chat" )
        {
            Gaim::Conversation::Chat::send($im, $message);
        } else {
            Gaim::Conversation::IM::send($im, $message);
        }
    } # end j
} # end rand_msg

#vim:tw=78:ts=4:ft=perl:norl:
