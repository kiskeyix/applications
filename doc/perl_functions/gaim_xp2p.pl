# $Id: gaim_xp2p.pl,v 1.3 2002-12-21 22:09:59 luigi Exp $
# Luis Mondesi < lemsx1@hotmail.com >
# Last modified: 2002-Dec-21
#
# Xtended Peer 2 Peer
#
# NOTE: this will freeze users computers, or crash their IM.
# Be polite! :-) GAIM does not get overloaded, but don't
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


# usefull variables:
$VERSION = "0.0.7";

$LIMIT = 10; # default limit for all text sent

# list of smiles
#@smilies = (":-)",":-D",":-P",":-O",":-(",":-S",":-|",";-)",":-\$",":'(",":-@");
@smilies = ("C:)","C:-)","O-)",">:)",">:-)",":-o)))",":-O)))","8-|)",":-]",":-)",":-(",";-)",":-P","=-O",":-*",">:o","8-)",":-\$",":-!",":-[","O:-)",":-/",":'(",":-X",":-D");
@msn_smilies = ("(a)","(A)",":-@",":@",":-[",":[","(B)","(b)","(Z)","(z)", 
		"(U)","(u)","(@)","(^)","(o)","(O)","(C)","(c)",":'(",":`(", 
		"(W)","(w)","(6)","(&)","(D)","(d)","(E)","(e)","(~)","(F)", 
		"(f)","(G)","(g)","(X)","(x)","(%)","(L)","(l)","(H)","(h)", 
		"(M)","(m)","(I)","(i)","(K)","(k)",":-D",":D",":-d",":d", 
		":->",":>",":-|",":|","(8)",":-O",":O",":-o",":o","(T)","(t)", 
		"(P)","(p)","(?)","(r)","(R)","({)","(})",":-(",":(",":-<", 
		"(S)","(s)",":-)",":)","(*)","(#)","(N)","(n)","(Y)","(y)", 
		":-P",":P",":-p",":p",":-S",":S",":-s",":s",";-)",";)", 
		":S-",":-\$",":\$");

# list of characters
@chars = qw/1 2 3 4 5 6 7 8 9 0 ! @ # $ % ^ & * ( ) _ + = ` ~ a b c d e f g h i j k l m n o p q r s t u v w x y z , < > ? [ ] { } " ' : ; | /;

sub description {
    my($a, $b, $c, $d, $e, $f) = @_;
    ("gaim_xp2p", "$VERSION", "The main purpose of this script is to bother people
if you don't want to bother them, then don't use this....\n
\n\t- _r ## or _rand ## or _are ##
        , sends random number of characters from global LIMIT/2 up to ##
        NOTE: added _are because r gets substituted by 'are' by default

\n\t- _s ## or _xs ##
        , _s sends random smilies up to ## 
            and _xs is the extended version of this... more smiles
        mostly MSN specific though

\n\t- _x message,## 
        , where message is a string that will be repeated ## times

\n\t- _z text,##
        , zig zags text ## number of times", 
        "Luis Mondesi &lt;lemsx1\@hotmail.com&gt;", "http://www.latinomixed.com/lems1", 
        "/dev/null");
}

GAIM::register("gaim_xp2p", $VERSION, "goodbye", "");

#$ver = GAIM::get_info(0);
#@ids = GAIM::get_info(1);

#$msg = "Gaim $ver:";
#foreach $id (@ids) {
    #	$pro = GAIM::get_info(7, $id);
    #	$nam = GAIM::get_info(3, $id);
    #	$msg .= "\n$nam using $pro";
    #}

# We know this already...
# GAIM::print("xp2p Says", $msg);

# GAIM::command("idle", 6000);

#GAIM::add_event_handler("event_buddy_signon", "echo_reply");
#GAIM::add_timeout_handler(60, "xtext_user");

# when sending IMs activate this
GAIM::add_event_handler("event_im_send", "xtext_user");
# when chatting...
GAIM::add_event_handler("event_chat_send", "xchat_user");

#sub echo_reply {
    #	$index = $_[0];
    #	$who = $_[1];
    #	GAIM::print_to_conv($index, $who, "Hello", 0);
    #}

    #sub notify {
        #	GAIM::print("1 minute", "gaim_xp2p has been loaded for 1 minute");
        #}

sub goodbye {
	GAIM::print("You Bastard!", "You killed gaim_xp2p");
}

sub xtext_user {
	$index = $_[0];
	$who = $_[1];
        $message = $_[2];
        
        #  _x string to repeat,##
        if ($message =~ m/.*_x /i) {
        
            # user wants to rock!
            # split text by commas
            ($message,$limit) = split(/,/,$message);
            
            #clean up message
            $message =~ s/_x //gi;
            # verify that $limit has digits and not something else
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
             
            for ($i=0;$i<$limit;$i++){
	        GAIM::print_to_conv($index, $who, $message, 0);
            } #end for
        } #end if

        # _s ##
        # sends ## of random smilies
        if ($message =~ m/.*_s /i) {
            # user wants random smilies
            ($limit = $message) =~ s/(.*_s|\s)//gi;
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            
            # reset $message
            $message = "";
            # pick random element
            for ($i=0;$i<$limit;$i++) {
                $message .= $smilies[rand @smilies]." "; #concat random faces
            } #end for
            
            GAIM::print_to_conv($index, $who, $message, 0);
        }# end if
        
	# _xs ##
        # sends ## of random smilies
        if ($message =~ m/.*_xs /i) {
            # user wants random smilies
            ($limit = $message) =~ s/(.*_xs|\s)//gi;
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            
            # reset $message
            $message = "";
            # pick random element
            for ($i=0;$i<$limit;$i++) {
                $message .= $msn_smilies[rand @msn_smilies]." "; #concat random faces
            } #end for
            
            GAIM::print_to_conv($index, $who, $message, 0);
        }# end if
	
        # _z string,##
        # zig zags text up to ##
         if ($message =~ m/.*_z /i) {
        
            # user wants to zig zag text 
            # split text by commas
            ($message,$limit) = split(/,/,$message);
            
            #clean up message
            $message =~ s/_z //gi;
            # verify that $limit has digits and not something else
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            
            $j = 0; # init another counter 
            for ($i=0;$i<$limit;$i++){
                if ( $j % 8 < 4 ) {
                    $wspace .= "   "; # add 3 spaces to text
                }else {
                    $wspace =~ s/[\s]{3}//o; # remove 3 spaces from text
                }
                $j++;
	        GAIM::print_to_conv($index, $who, $wspace.$message, 0);
            } #end for
        } #end if
        
        # _rand ## or _r ##
        # send random stuff up to ##
        if ($message =~ m/.*_rand |.*_r |.*_are /i) {
            ($limit = $message) =~ s/(_rand|\s|_r|_are)//gi;
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            $limit = random_int_in(($LIMIT/2),$limit);
            
            for ($j=0;$j<$limit;$j++) {
                
                $message = ""; # reset message
                # to make things a little bit more exciting!
                # multiply limit times 8 number of characters
                # but, if this number happens to be greater than
                # 256, then only generate 255 number of chars
                for ($i=0;$i<((($limit*8)<256)? $limit*8 : 255) ;$i++) {
                    $message .= $chars[rand @chars];
                } # end i

                GAIM::print_to_conv($index, $who, $message, 0);
            
            } # end j
        }
       
        # message will get display by default
}

sub xchat_user {
	$index = $_[0];
	$who = $_[1];
        $message = $_[2];
        
        #  _x string to repeat,##
        if ($message =~ m/.*_x /i) {
        
            # user wants to rock!
            # split text by commas
            ($message,$limit) = split(/,/,$message);
            
            #clean up message
            $message =~ s/_x //gi;
            # verify that $limit has digits and not something else
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
             
            for ($i=0;$i<$limit;$i++){
	        GAIM::print_to_chat($index, $who, $message);
            } #end for
        } #end if

        # _s ##
        # sends ## of random smilies
        if ($message =~ m/.*_s /i) {
            # user wants random smilies
            ($limit = $message) =~ s/(_s|\s)//gi;
            #$limit =~ s/_s //g;
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            
            # reset $message
            $message = "";
            # pick random element
            for ($i=0;$i<$limit;$i++) {
                $message .= $smilies[rand @smilies]." "; #concat random faces
            } #end for
            
            GAIM::print_to_chat($index, $who, $message);
        }# end if

        # _xs ##
        # sends ## of random smilies
        if ($message =~ m/.*_xs /i) {
            # user wants random smilies
            ($limit = $message) =~ s/(_xs|\s)//gi;
            #$limit =~ s/_s //g;
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            
            # reset $message
            $message = "";
            # pick random element
            for ($i=0;$i<$limit;$i++) {
                $message .= $msn_smilies[rand @msn_smilies]." "; #concat random faces
            } #end for
            
            GAIM::print_to_chat($index, $who, $message);
        }# end if
	
        # _z string,##
        # zig zags text up to ##
         if ($message =~ m/.*_z /i) {
        
            # user wants to zig zag text 
            # split text by commas
            ($message,$limit) = split(/,/,$message);
            
            #clean up message
            $message =~ s/_z //gi;
            # verify that $limit has digits and not something else
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            
            $j = 0; # init another counter 
            for ($i=0;$i<$limit;$i++){
                if ( $j % 8 < 4 ) {
                    $wspace .= "   "; # add 3 spaces to text
                }else {
                    $wspace =~ s/[\s]{3}//o; # remove 3 spaces from text
                }
                $j++;
	        GAIM::print_to_chat($index, $who, $wspace.$message);
            } #end for
        } #end if
        
        # _rand ## or _r ##
        # send random stuff up to ##
        if ($message =~ m/.*_rand |.*_r |.*_are /i) {
            ($limit = $message) =~ s/(_rand|\s|_r|_are)//gi;
            $limit = ($limit =~ /\d/) ? $limit : $LIMIT;
            $limit = random_int_in(($LIMIT/2),$limit);
            
            for ($j=0;$j<$limit;$j++) {
                
                $message = ""; # reset message
                # to make things a little bit more exciting!
                # multiply limit times 8 number of characters
                # but, if this number happens to be greater than
                # 256, then only generate 255 number of chars
                for ($i=0;$i<((($limit*8)<256)? $limit*8 : 255) ;$i++) {
                    $message .= $chars[rand @chars];
                } # end i

                GAIM::print_to_chat($index, $who, $message);
            
            } # end j
        }
       
        # message will get display by default
}
# contrib function to get a random number
sub random_int_in ($$) {
    my($min, $max) = @_;
    # Assumes that the two arguments are integers themselves!
    return $min if $min == $max;
    ($min, $max) = ($max, $min)  if  $min > $max;
    return $min + int rand(1 + $max - $min);
} # end random # generator
