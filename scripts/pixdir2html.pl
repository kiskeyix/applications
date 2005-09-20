#!/usr/bin/perl 
# $Revision: 1.101 $
# Luis Mondesi  <lemsx1@gmail.com>
# 
# HELP: $0 --help
# DESC: pixdir2html - makes thumbnails and custom html files for pictures
# REQUIRED: ImageMagick's Perl module and a dialog 
#           program or Term::Pogressbar Perl module
use strict;
$|++; # disable buffer (autoflush)

# standard Perl modules
use Getopt::Long;
Getopt::Long::Configure('bundling');
use File::Spec::Functions  qw(splitpath curdir updir catfile catdir splitpath);
use File::Copy;
use File::Find;     # find();
use File::Basename; # basename() && dirname()
use FileHandle;     # for progressbar
use Cwd;            # same as: qx/pwd/

# non-standard modules:
my $USE_CONVERT=0;
eval "use Image::Magick";
if ($@) 
{
    print STDERR "\nERROR: Could not load the Image::Magick module.\n" .
    "       To install this module use:\n".
    "       Use: perl -e shell -MCPAN to install it.\n".
    "       On Debian just: apt-get install perlmagic \n\n".
    "       FALLING BACK to 'convert'\n\n";
    print STDERR "$@\n";
    if ( -x "/usr/bin/convert" || -x "/usr/local/bin/convert" )
    {
        $USE_CONVERT=1;
    } else {
        print STDERR "\nERROR: 'convert' was not found in /usr/bin or \n".
        "/usr/local/bin. \n Exiting...\n\n";
        exit 1;
    }
}

# Get Nautilus current working directory, if under Natilus:
my $nautilus_root = "";
if ( exists $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} 
    && $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} =~ m#^file:///# 
) 
{
    ($nautilus_root = $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'} ) =~ s#%([0-9A-Fa-f]{2})#chr(hex($1))#ge;
    ($nautilus_root = $nautilus_root ) =~ s#^file://##g;
}
my $ROOT_DIRECTORY= ( -d $nautilus_root ) ? $nautilus_root : ".";
my $LOG="$ROOT_DIRECTORY/pixdir2html.log";
my $CONFIG_FILE=".pixdir2htmlrc";
my $THUMBNAIL="t";  # individual thumnails files will be placed here
my $HTMLDIR="h";    # individual HTML files
my $THUMB_PREFIX = "t"; # no need to ever change this... this starts
# the name for all thumbnail images
# list directories that should be skipped here
# separated by |
my $EXCEPTION_LIST = "CVS|RCS";
# regex of files we want to include
my $EXT_INCL_EXPR = "\.(jpg|png|jpeg|gif)";
# dont worry if you don't have a log rotation facility...
# just leave it as is
my $SAVELOG = "/usr/bin/savelog";
my $SKIP_DIR_FILE=".nopixdir2htmlrc"; # filename to flag directories to skip

#**************************************************************#
###        Nothing below this line should be changed.        ###
#**************************************************************#
my @pixdir = ();        # for menu
my @pixfiles = ();      # for all picture files
my %thumbfiles = ();    # hash of arrays for all thumbnails 
                        # created by mkthumb
my %config = ();        # hash of hashes to hold config per directories
my $TOTAL_LINKS=0;
my $FORCE=0; 
my $NOMENU=0; 
my $MENUONLY=0;
my $THUMBSONLY=0;
my $CUT_DIRS=0;
my $NOINDEX=0;
my $HELP=0;
my $PVERSION=0;
# How big are the thumbnails?
my $PERCENT="20%";
# How many TDs per table in e/a index.EXT?
my $TD=4;
# How many TDs per menu table?
my $menu_td=10;
# How big are strings in menus?
my $STR_LIMIT = 32;
# progressbar stuff here:
my $GAUGE = new FileHandle;
my $MODE = "text";
my $DIA = "";
my $use_console_progressbar = 0; # a simple flag
my $MENU_TYPE="";   # default menu-type is "classic". 
                    # put 'menu-type: modern' in config 
                    # or pass --menu-type="modern" from 
                    # command line to change

my $EXT="html";     # default extension for generated HTML files
my $FILE_NAME="index";
my $MENU_NAME="menu"; 
my $NEW_MENU_NAME="";
# others
my $menu_str="";
my $revision="Pixdir2html v1.8\n Luis Mondesi <lemsx1\@hotmail.com>\n";
# get options
GetOptions(
    # flags
    'v|version'         =>  \$PVERSION,
    'n|no-menu'         =>  \$NOMENU,
    'f|force'           =>  \$FORCE,
    'h|help'            =>  \$HELP,
    'M|menu-only'       =>  \$MENUONLY,
    't|thumbs-only'     =>  \$THUMBSONLY,
    'N|no-index'        =>  \$NOINDEX,
    # strings
    'E|extension=s'     =>  \$EXT,
    'D|directory=s'     =>  \$ROOT_DIRECTORY,
    'F|front-end=s'     =>  \$DIA,
    'm|menu-type=s'     =>  \$MENU_TYPE,
    'menu-name=s'       =>  \$NEW_MENU_NAME,
    # numbers
    'menu-td=i'         =>  \$menu_td,
    'l|menu-links=i'    =>  \$menu_td,
    'td=i'              =>  \$TD,
    'str-limit=i'       =>  \$STR_LIMIT,
    'c|cut-dirs=i'      =>  \$CUT_DIRS
);
if ( $HELP ) { 
    use Pod::Text;
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file(File::Spec->catfile("$0"),
			   \*STDOUT);
    exit 0;
}

if ( $PVERSION ) { print STDOUT ($revision); exit 0; }
# Xdialog is a better implementation than gdialog. 
# Zenity is better than all so far... 
my @xbinaries = ("zenity","Xdialog","xdialog","gdialog","kdialog");
my @binaries = ("dialog","whiptail","cdialog"); 
my $FOUND = 0; # flag
if ( $DIA eq "console" ) {
    print STDERR ("Trying Term::ProgressBar\n");
    eval "use Term::ProgressBar";
    if ( ! $@ ) { 
        $use_console_progressbar = 1; # update flag
    } else {
        # no hope at this point... 
        print STDERR ("Run without --front-end='console' to autodetect dialog\n");
        print STDERR ("Term::ProgressBar is not installed. Exiting\n");
        exit 1;
    }
} elsif ( $DIA eq "" ) {
    foreach my $path ( split(/:/,$ENV{"PATH"}) )
    {
        next if ( $FOUND == 1 );
        if ( exists $ENV{"NAUTILUS_SCRIPT_CURRENT_URI"} )
        {
            $MODE = "x";
            foreach my $binary ( @xbinaries ) {
                next if ( $FOUND == 1 );
                if ( -x "$path/$binary" ) {
                    $DIA = "$path/$binary";
                    # gets out of these loops
                    $FOUND = 1; 
                }
            } # end foreach @xbinaries
        } else {
            $MODE = "text";
            foreach my $binary ( @binaries ) {
                next if ( $FOUND == 1 );
                if ( -x "$path/$binary" ) {
                    $DIA = "$path/$binary";
                    $FOUND = 1; 
                }
            } # end foreach @binaries
        } # end if NAUTILUS_SCRIPT_CURRENT_URI
    } # end foreach $PATH
    # make sure DIA is set or exit abnormally
    if ( $MODE eq "x" ) {
        if ( $DIA eq "" ) { 
            # error
            print STDERR ("Graphical Dialog was not found.\n");
            print STDERR ("Please install any of these programs:\n");
            print STDERR join(" ",@xbinaries)."\n";
            exit 1;
        }
    } elsif ( $MODE eq "text" ) {
        if ( $DIA eq "" ) {
            # error only if no DIA
            # being userfriendly here... 
            print STDERR ("Console Dialog was not found.\n");
            print STDERR ("Please install any of these programs:\n");
            print STDERR join(" ",@binaries)."\n";
            # fallback to console...
            print STDERR ("Trying Term::ProgressBar\n");
            eval "use Term::ProgressBar";
            if ( ! $@ ) { 
                print STDERR ("Using Term::Progressbar\n");
                $use_console_progressbar = 1; # update flag
            } else {
                # yikes! no hope at this point... 
                print STDERR ("Term::ProgressBar is not installed. Exiting\n");
                exit 1;
            }
            # we should never reach this...
            exit 1;         
        } # end if DIA eq console
    } # end if MODE
} # end if DIA
my $LOGFILE = new FileHandle;
my $THUMBNAILSDIR="$ROOT_DIRECTORY/$THUMBNAIL";
my $HTMLSDIR="$ROOT_DIRECTORY/$HTMLDIR";

main();
#-------------------------------------------------#
#                   FUNCTIONS                     #
#-------------------------------------------------#

sub main {
    $LOGFILE->open("> $LOG");
    $LOGFILE->autoflush(1);
    my $err = 0;
    my $ARGS = ( $DIA =~ /zenity/ ) ? "" : " --clear --backtitle 'Picture Directory to HTML' ";
    if ( $use_console_progressbar == 1 ) 
    {
        $GAUGE = Term::ProgressBar->new(100); # will be setup later...
    } else {
        if ( $DIA =~ /zenity/ )
        {
            # zenity uses --progress # 'Thumbnails Creation'
            $GAUGE->open("| $DIA $ARGS --title='Picture Directory to HTML' --progress  8 70 0 2>&1");
        } else {
            $GAUGE->open("| $DIA $ARGS --title 'Picture Progress' --gauge 'Thumbnails Creation' 8 70 0 2>&1");
        }
        $GAUGE->autoflush(1);
    }
    # which progressbar are we using?
    print $LOGFILE ("Mode $MODE\n");
    print $LOGFILE "= Start directory $ROOT_DIRECTORY \n";

    # setup our internal variables:
    my $create_config = ( ! -f File::Spec->catfile($ROOT_DIRECTORY,$CONFIG_FILE) ) ? "true":"false";
    init_config($ROOT_DIRECTORY,$create_config);

    # --------------------------- STEPS -----------------------------#
    # 1.
    # Create an array of all image files that we will work on.
    # HINT: check EXCEPT for files we will be ignoring.
    my @ary = do_file_ary($ROOT_DIRECTORY);
    # remove duplicates:
    my %seen = ();
    my @uniq = grep(!$seen{$_}++,@ary);
    @pixfiles = @uniq; # copies all unique files to pixfiles
    # free up memory:
    @ary = ();
    %seen = ();
    @uniq = ();
    undef @ary;
    undef %seen;
    undef @uniq;
    # 2.
    # we need to create thumbnails first... 
    # make all thumbnails and save all thumbs in %thumbfiles
    # so that mkindex() can create the indices.
    $err = mkthumb($ROOT_DIRECTORY);
    exit(0) if ( $err > 0 or $THUMBSONLY > 0 );
    
    # 3.
    # We need to create a menu string to pass it to mkindex()
    if ( $NOMENU != 1 or $config{$ROOT_DIRECTORY}{"menutype"} eq "modern" ) 
    {
        print $LOGFILE ("= Creating menu string\n");
        $menu_str = menu_file();
        # When menuonly is set, we print to a menu.$EXT file and exit
        exit(0) if ( $MENUONLY > 0 );
    } 

    if ( $NOINDEX == 0 )
    {
        # 4.
        # make all supporting HTML files for e/a thumbnail image. 
        # i.e. under the "t" directory
        #
        # TODO this should use %thumbfiles (see mkindex())
        mkthumb_files(\%thumbfiles);
        
        # 5.
        # create index.$EXT files for thumbnails. The index file contains
        # the links to e/a h/t$file.$EXT
        mkindex(\%thumbfiles,$menu_str);
    }

    # close progressbar
    if ( $use_console_progressbar != 1 ) 
    {
        eof($GAUGE);
    }
    undef($GAUGE); # this also closes the gauge... but...
    # close log
    $LOGFILE->close();
    if ( -x $SAVELOG ) {
        system("$SAVELOG $LOG > /dev/null 2>&1");
    }
    return 0;
} # endmain

sub write_config
{
    # @param 0 string := directory to write $CONFIG_FILE to
    # @param 1 hashref := hash of hashes containing what to write
    my $dir = shift;
    my $hashref = shift;
    if (open(CONFIG, ">$dir/$CONFIG_FILE")) {
        foreach my $key ( keys %{$hashref} ) {
            foreach my $subkey ( keys %{$hashref->{$key}} ) {
                print CONFIG 
                "$subkey=" . $hashref->{"$key"}->{"$subkey"}."\n";
            }
        }
    } else {
        print STDERR 
        "Could not write $dir/$CONFIG_FILE. Check permissions?";
    }
    close(CONFIG);
} # end write_config

sub init_config {
    # @param 0 string := directory with config file   
    # @param 1 string := optional, do we want to create a config file?
    # saves found variables to global %config database
    my $ROOT = shift;
    my $create_config = shift;
    my $line="";

    # some defaults:
    #
    # it's very important to set this to a 
    # full URI:
    # file:///path/to/root/directory
    # http://www.server.tld/path/to/root/directory
    # where "root directory" is the main dir
    # where all other directories reside (and not
    # the / root filesystem of UNIX/Linux/...).
    # For now, ".." do the trick for a simple
    # tree of directories:
    # ROOT/
    # ROOT/dir_a
    # ROOT/dir_b
    # ROOT/dir_c
    #
    # and not
    # ROOT/
    # ROOT/dir_a/dir_a1/dir_a2
    # ROOT/dir_b ...
    # for which case you will need a full path
    # Some default values:
    $config{"$ROOT"}{"uri"}=".."; # might need modifications
    $config{"$ROOT"}{"percent"}=( $PERCENT ) ? $PERCENT : "20%";
    $config{"$ROOT"}{"title"}="Images";
    $config{"$ROOT"}{"meta"}="<meta http-equiv='content-type' content='text/html;charset=iso-8859-1'>";
    $config{"$ROOT"}{"stylesheet"}="../styles.css";
    $config{"$ROOT"}{"html_msg"}="<h1 class='pdheader1'>Free form HTML</h1>";
    $config{"$ROOT"}{"body"}="<body class='pdbody'>";
    $config{"$ROOT"}{"p"}="<p class='pdparagraph'>";
    $config{"$ROOT"}{"table"}="<table border='0' class='pdtable'>";
    $config{"$ROOT"}{"td"}="<td valign='top' align='left' class='pdtd'>";
    $config{"$ROOT"}{"tr"}="<tr class='pdtr'>";
    # when header is set, title, meta, stylesheet, etc...
    # are discarded. So do a complete set
    # such as <HTML><head><title>...
    # and close with "footer"
    $config{"$ROOT"}{"header"}="";
    $config{"$ROOT"}{"footer"}="";
    $config{"$ROOT"}{"menuheader_footer"}=0;
    # ext can be passed in a .pixdir2htmlrc file
    # like: ext=html or ext=php ...
    $config{"$ROOT"}{"ext"}=( $EXT ) ? $EXT : "html" ;
    $config{"$ROOT"}{"menutype"}=( $MENU_TYPE ) ? $MENU_TYPE : "classic";
    $config{"$ROOT"}{"menuname"}=( $MENU_NAME ) ? $MENU_NAME : "menu";
    $config{"$ROOT"}{"menutd"}=( $menu_td ) ? $menu_td : 10;
    $config{"$ROOT"}{"ntd"}=( $TD ) ? $TD : 4 ;
    $config{"$ROOT"}{"strlimit"}=( $STR_LIMIT ) ? $STR_LIMIT : 32;
    $config{"$ROOT"}{"cutdirs"}=( $CUT_DIRS ) ? $CUT_DIRS : 0 ;

    my $config_file = File::Spec->catfile($ROOT,$CONFIG_FILE);
    if ( -f $config_file )
    {
        open( CONFIG,"< $config_file" )
            or mydie("Could not read $config_file\n","init_config");
        # suppress warnings for now... 
        no warnings; 
        while ( defined($line = <CONFIG>) ) {
            next if /^\s*#/;
            chomp $line;
            # attempts to be forgiven about backslashes
            # to break lines that continues over
            # multiple lines
            if ($line =~ s/\\$//) {
                $line .= <CONFIG>;
                redo unless eof(CONFIG);
            }
            $config{$ROOT}{$1} = $2 if ( $line =~ m,^\s*([^=]+)=(.+), );
        }
        close(CONFIG);
    } 
    
    #construct a header if it doesn't yet exist:
    if ( $config{"$ROOT"}{"header"} =~ /^\s*$/ ) 
    {
        print $LOGFILE (": Blank header. Generating my own [$ROOT] ... \n");
        $config{"$ROOT"}{"header"}="<html><head>".
        $config{"$ROOT"}{"meta"}.
        "<title>".
        $config{"$ROOT"}{"title"}.
        "</title><link rel='stylesheet' href='".
        $config{"$ROOT"}{"stylesheet"}.
        "' type='text/css'></head>".
        $config{"$ROOT"}{"body"}."<center>".
        $config{"$ROOT"}{"html_msg"};
    }
    #construct a footer if it doesn't yet exist:
    if ( $config{"$ROOT"}{"footer"} =~ /^\s*$/ )
    {
        print $LOGFILE (": Blank footer. Generating my own [$ROOT] ... \n");
        $config{"$ROOT"}{"footer"}="</center></body></html>";
    }
    # write configuration 
    if ( $create_config =~ /true/ ) 
    {
        # uncomment for debugging...
        #use Data::Dumper;
        #print STDOUT Dumper(%config);
        #print STDOUT "\n\n\n";
        write_config($ROOT,\%config);
    }
    warn "Could not find $config_file\n" if ( ! -f $config_file );
} # end init_config

sub mkindex {
    # @param 0 hash :=
    #   takes a two-dimensional hash of arrays in the form:
    #   $name{base}->[0] = 'path/file'
    #   and does a index.$EXT file for e/a 'base' of
    #   all files referenced 
    # @param 1 string := menu to use for e/a file

    my $hashref = $_[0];    # saves the name of the var passed
                            # e/a key holds a full array of files
    my $MENU_STR = $_[1]; 
    my $i = 0;
    my ( $this_file, $this_base ) = "";     # holds keys for hash
    my @files = ();

    foreach $this_base ( sort keys %$hashref ) {
        next if ( -f File::Spec->catfile($this_base,$SKIP_DIR_FILE) );
        my ($my_bgcolor,$file_name) = ""; 
        $i = 0;
        # read specific config file for this directory
        if ( ! -f File::Spec->catfile($this_base,$CONFIG_FILE) )
        {
            # oops, missing config file copying from root dir
            if ( 
                copy(File::Spec->catfile($ROOT_DIRECTORY,$CONFIG_FILE), 
                    File::Spec->catfile($this_base,$CONFIG_FILE)) 
            ) {
                print $LOGFILE (": mkindex() Copied ".
                    " $ROOT_DIRECTORY/$CONFIG_FILE ".
                    "==> $this_base/$CONFIG_FILE \n");
            }
        } # end if/elsif
        if (! exists $config{$this_base} )
        {
            # this should rarely happen
            print $LOGFILE "++ mkindex() Reading config for '$this_base'\n";
            init_config($this_base,"false");
        }
        # "serialization"
        my @files = @{$$hashref{"$this_base"}};

        dict_sort(\@files);

        # FILE_NAME is a global
        open(FILE, "> ".$this_base."/".$FILE_NAME.".".$config{"$this_base"}{"ext"}) || 
        mydie("Couldn't write file $FILE_NAME.".$config{"$this_base"}{"ext"}." to $this_base","mkindex");

        # start HTML
        print FILE ($config{"$this_base"}{"header"}."\n");
        # print menu (if any)
        print FILE ("$MENU_STR");
        # start table
        print FILE ($config{"$this_base"}{"table"}."\n");
        #print all picts now
        foreach(@files){
            $this_file = basename($_);
            if ($i == 0) {
                # open a new row
                # this row doesn't need bgcolor
                if ( $config{"$this_base"}{"tr"} =~ m/\%+bgcolor\%+/i ) {
                    my $tmp_tr = "";
                    ( $tmp_tr = $config{"$this_base"}{"tr"} ) 
                        =~ s/\%+bgcolor\%+//i;
                    print FILE ($tmp_tr);
                } else {
                    print FILE ($config{"$this_base"}{"tr"}."\n");
                }
            } 
            print FILE ("\t".$config{"$this_base"}{"td"}."\n");
            ($file_name = $this_file) =~ s/$EXT_INCL_EXPR//gi;
            ($file_name = $file_name) =~ s/^$THUMB_PREFIX//; # removes prefix
            # EXT is a global and so is THUMBNAIL
            print FILE ("\t\t<a class='pdlink' href='$HTMLDIR/$file_name.".$config{"$this_base"}{"ext"}."'>".
                "\t\t<img class='pdimage' src='$THUMBNAIL/"."$this_file' border=0 alt='$file_name'></a>\n");
            print FILE ("\t</td>\n");
            if ($i<($TD-1)) {
                $i++;
            } else {
                # wrap and reset counter
                print FILE ("</tr>\n");
                $i = 0;
            }
        } # end for e/a @files
        # complete missing TD
        if ($i != 0) {
            for (;$i<$TD;$i++) {
                print FILE ("\t".$config{"$this_base"}{"td"}."\n");
                print FILE ("&nbsp;");
                print FILE ("\t</td>\n");
            }
        }
        print FILE ("</tr>\n");
        print FILE ("</table>\n");
        print FILE ($config{"$this_base"}{"footer"}."\n");
        print FILE ("\n");
        close(FILE);
    } # end for e/a this_base
} # end mkindex

sub mkthumb {
    # Creates thumbnails for a given directory
    # and save all to the global hash %thumbfiles
    # @param 0 := root dir to make the images
    #
    my $ROOT = $_[0];
    # globals
    %thumbfiles = (); # reset
    # locals: reset some locals
    my @ls = ();
    my ($this_file,
        $pix_name,
        $file_name,
        $next_pix_name,
        $next_file_name,
        $last_pix_name,
        $last_html_file,
        $current_html_file,
        $last_file_name,
        $current_link,
        $last_link,
        $LAST_BASE,
        $NEXT_BASE,
        $HTMLSDIR) = "";
    # these two are special...
    # init to some strange string...
    my $BASE = ",\/trash";
    my $tmp_BASE = ",\/more_trash";
    # error reporting:
    my $err = 0;
    my $i = 0;
    my $image = Image::Magick->new; # image::magick is installed?

    print $LOGFILE ("= Making thumbnails in $ROOT \n");
    if ( ! defined $pixfiles[0] or ! -f $pixfiles[0] ) 
    {
        mydie("Sorry, do_file_ary() didn't do its job\n","mkthumb");
    }

    # parse array of images
    foreach (@pixfiles) {
        $this_file = basename($_);
        next if ($this_file =~ m/$EXCEPTION_LIST/);
        next if ($_ =~ m/\b$THUMBNAIL\b/i);
        next if ($this_file !~ m/$EXT_INCL_EXPR$/i);
        push @ls,$_;
        $this_file = "";
    } #end images array creation
    #print STDERR @ls;
    dict_sort(\@ls);

    # progressbar stuff
    # gauge message
    my $MESSAGE = "Thumbnails Creation";
    # initial values for gauge
    my $PROGRESS = 0;
    my $TOTAL = $#ls + 1;
    if ( $use_console_progressbar == 1 )
    {
        $GAUGE->new({'name'=>$MESSAGE,'count'=>$TOTAL});
    } else {
        progressbar_msg($MESSAGE);
    }
    print $LOGFILE ("= $TOTAL pictures \n");
    #print $LOGFILE join(" ",@ls)."\n";
    for ( $i=0; $i < $TOTAL; $i++) 
    {
        $PROGRESS++; 
        # get base directory
        $BASE = dirname($ls[$i]);
        # BASE is blank if we are already inside the directory
        # for which to do thumbnails, thus:
        if ( not defined ($BASE) or $BASE eq "" or ! -d $BASE ) 
        { 
            $BASE = "."; 
        }
        next if ( -f File::Spec->catfile($BASE,$SKIP_DIR_FILE) );
        next if ($BASE eq $THUMBNAIL); 
        if ( $BASE ne $tmp_BASE )
        {
            # Note that this tmp_BASE comparison is meant
            # to avoid doing this for e/a directory more than once:
            if (  $FORCE > 0 or ! -f File::Spec->catfile($BASE,$CONFIG_FILE) )
            {
                copy(File::Spec->catfile($ROOT_DIRECTORY,$CONFIG_FILE), 
                    File::Spec->catfile($BASE,$CONFIG_FILE)) 
                    or mydie("Could not copy $ROOT_DIRECTORY/$CONFIG_FILE to $BASE/$CONFIG_FILE. $!","mkthumb");
                print $LOGFILE (": Copied $ROOT_DIRECTORY/$CONFIG_FILE ==> $BASE/$CONFIG_FILE \n");
            } # end if missing $CONFIG_FILE
            # read specific config file for this directory
            if ( ! exists $config{$BASE} )
            {
                print $LOGFILE "+ mkthumb Reading config for '$BASE'\n";
                init_config($BASE,"false");
            }
        } # end if base not equal tmp_base
        # update flag
        $tmp_BASE = $BASE;
                
        $pix_name = basename($ls[$i]);
        # strip extension from file name
        ($file_name = $pix_name) =~ s/$EXT_INCL_EXPR$//gi;
        # construct PATH for thumbnail directory
        $THUMBNAILSDIR=File::Spec->catfile($BASE,$THUMBNAIL);

        if ( ! -d $THUMBNAILSDIR )
        { 
            print $LOGFILE ("= Making thumbnail's directory in $BASE\n");
            mkdir($THUMBNAILSDIR,0755);
        }

        if ( !-f File::Spec->catfile($THUMBNAILSDIR,$THUMB_PREFIX.$pix_name) )
        {
            print $LOGFILE ("\n= Converting file $BASE/$pix_name into $THUMBNAILSDIR/$THUMB_PREFIX"."$pix_name \n");
            if ( $USE_CONVERT == 1 )
            {
                system("convert -geometry $PERCENT ".File::Spec->catfile($BASE,$pix_name)." ".File::Spec->catfile($THUMBNAILSDIR,$THUMB_PREFIX.$pix_name) );
                if ( $? != 0 ) {
                    print $LOGFILE "** ERROR: conversion failed: $! \n";
                    $err = 1;
                }
            } else {
                # assumes Image::Magick was checked for before
                $image->Read( File::Spec->catfile($BASE,$pix_name) );
                $image->Resize($PERCENT);
                $image->Write( File::Spec->catfile($THUMBNAILSDIR,$THUMB_PREFIX.$pix_name) );
            }
            print $LOGFILE ("\n"); 
        } 
        # end if thumbnail file
        
        # save pixname for the index.html file
        push @{$thumbfiles{$BASE}}, File::Spec->catfile($THUMBNAILSDIR,$THUMB_PREFIX.$pix_name);
        # update flags
        $LAST_BASE = $BASE;
        # update progressbar
        if ( $use_console_progressbar == 1 ) 
        {
            $GAUGE->update($PROGRESS);
        } else {
            progressbar($PROGRESS,$TOTAL);
        }
    } #end for @ls 
    return $err;
} # end mkthumb

sub mkthumb_files {
    # creates an HTML file for e/a thumbnail 
    # @param 0 hash := $name{$base}->[$i] = 'path/file'
    my $hashref = shift;
    mydie("Error while creating thumb_files HTML indeces\n","mkthumb_files") 
        if (not defined $hashref);
    # locals
    my @ls = ();
    my $i = 0;
    my ($this_file,
        $pix_name,
        $file_name,
        $next_pix_name,
        $next_file_name,
        $last_pix_name,
        $current_html_file,
        $last_file_name,
        $current_link,
        $last_link,
        $LAST_BASE,
        $NEXT_BASE,
        $HTMLSDIR) = ""; 
    # TODO find a more elegant solution here
    # init to dummy string:
    my $BASE = "trash/\\file";
    my $last_html_file = "this_is/dummy\\string";

    # some sanity checks plus "serializes" our hashref into a more manageable array @ls
    # TODO are this really needed?
    foreach my $this_base ( keys %$hashref )
    {
        foreach (@{$hashref->{$this_base}}){
            $this_file = basename($_);
            next if (not defined ($this_file));
            next if ($this_file =~ m/$EXCEPTION_LIST/);
            next if ($this_file !~ m/$EXT_INCL_EXPR$/i);
            next if ($_ =~ m/\/$THUMBNAIL\/.*$EXT_INCL_EXPR$/i);
            push @ls,$_;
            $this_file = undef;
        } #end images array creation
    }
    dict_sort(\@ls);

    # progressbar stuff
    # gauge message
    my $MESSAGE = "HTML Creation";
    # initial values for gauge, note total
    # is number of elements in array ;-) 
    my $PROGRESS = 0;
    # $#VAR gets index of last element in an array
    my $TOTAL = $#ls + 1;
    if ( $use_console_progressbar == 1 )
    {
        $GAUGE->new({'name'=>$MESSAGE,'count'=>$TOTAL});
    } else {
        progressbar_msg($MESSAGE);
    }
    #print all picts now
    for ( $i=0; $i < $TOTAL; $i++) {
        $PROGRESS++;
        # get base directory
        $BASE = dirname( $ls[$i] );
        next if ($BASE eq $THUMBNAIL);
        # BASE is blank if we are already inside the directory
        # for which to do thumbnails, thus:
        if ( ! -d $BASE ) { 
            print $LOGFILE "+ mkthumb_files changed based $BASE to .\n";
            $BASE = "."; 
        }
        next if ( -f File::Spec->catfile($BASE,$SKIP_DIR_FILE) );
        $pix_name = basename($ls[$i]);
        # strip extension from file name
        ($file_name = $pix_name) =~ s/$EXT_INCL_EXPR$//gi;
        # if we have not already read this config file,
        # do so now:
        if ( ! exists $config{$BASE} ) 
        {
            print $LOGFILE "+ mkthumb_files Reading config for '$BASE'\n";
            init_config($BASE,'false');
        }
        
        # construct PATH for html directory
        $HTMLSDIR = File::Spec->catfile($BASE,$HTMLDIR);
        if (!-d $HTMLSDIR)
        { 
            print $LOGFILE ("= Making HTML directory in $BASE\n");
            mkdir($HTMLSDIR,0755);
        }

        $current_html_file = File::Spec->catfile($HTMLSDIR,$file_name.$config{$BASE}{"ext"});
        $current_link = $file_name.".".$config{$BASE}{"ext"};

        my $msg = "= Creating";
        if ( -f $current_html_file )
        {
            $msg = ": Overriding";
        }
        print $LOGFILE ("$msg html file '$current_html_file'\n");
        # TODO routine for creating file should be called here...
        open(FILE, "> $current_html_file") or
            mydie("Couldn't write file $current_html_file","mkthumb_files");

        # start HTML
        print FILE ($config{"$BASE"}{"header"}."\n");
        # start table
        print FILE ($config{"$BASE"}{"table"}."\n");
        # set menu-name now (from command-line or config file)
        if ( $NEW_MENU_NAME gt "" ) 
        {
            $MENU_NAME=$NEW_MENU_NAME;
        } elsif ( defined($config{"$ROOT_DIRECTORY"}{"menuname"}) 
            and $config{"$ROOT_DIRECTORY"}{"menuname"} gt "" ) {
            $MENU_NAME=$config{"$ROOT_DIRECTORY"}{"menuname"};
        } # else MENU_NAME keeps the default name
        
        if ( $config{"$BASE"}{"menutype"} eq "modern" )
        {
            # TODO use relative path instead of URI here
            print FILE ("\t\t<a class='pdlink' href='".$config{"$BASE"}{"uri"}."/".$MENU_NAME.".".$config{"$BASE"}{"ext"}."'>&lt;&lt;</a>\n");
        }
        # backward link here
        if ( $last_html_file ne "this_is/dummy\string" 
            and -f $last_html_file 
            and ($BASE eq $LAST_BASE) ) 
        {
            print FILE ("\t\t<a class='pdlink' href='$last_link'>&lt;==</a>\n"); 
        } else {
            print FILE ("&lt;==");
        }
        # home link here # TODO ../ should be replaced with relative str
        print FILE ("\t\t | <a class='pdlink' href='../$FILE_NAME.".$config{"$BASE"}{"ext"}."'>HOME</a> | \n");

        if ( -f $ls[$i+1] ) {
            $next_pix_name = "....";
            # calculate next base
            $next_pix_name = basename($ls[$i+1]);
            # get next base directory
            $NEXT_BASE = dirname($ls[$i+1]);
        }
        # forward link here
        if ( -f $ls[$i+1] and ($BASE eq $NEXT_BASE) ) {
            $next_file_name = "";
            ($next_file_name = $next_pix_name) =~ s/$EXT_INCL_EXPR$//gi;
            #print FILE ("==&gt;");
            print FILE ("\t\t<a class='pdlink' href='$next_file_name.".$config{"$BASE"}{"ext"}."'>==&gt;</a> \n");
        } else {
            print FILE ("==&gt;");
            # TODO would be nice to jump to next directory in the
            #       array... 
            #print FILE (" <a href='../$next_file_name.$EXT'>&gt;&gt;</a> \n");
        }
        print FILE ("</div></td></tr>\n");
        print FILE ("<tr><td align='center'>\n<div align='center'>\n");
        # image here # TODO ../ should be replaced with relative str
        print FILE ("<img src='../$pix_name' alt='$file_name' border=0>\n");
        print FILE ("</div></td></tr>\n<tr><td valign='bottom' align='center'><div align='center'>\n");
        print FILE ("</table>\n");
        print FILE ($config{"$BASE"}{"footer"}."\n");
        close(FILE);
        # end HTML
        # keep track of links
        $last_html_file = $current_html_file;
        $last_link = $current_link;
        # update flags
        $LAST_BASE = $BASE;
        $NEXT_BASE = "";
        #$PRINT_NEXT_LINK = 0;
        # update progressbar
        if ( $use_console_progressbar == 1 )
        {
            $GAUGE->update($PROGRESS);
        } else {
            progressbar($PROGRESS,$TOTAL);
        } 
    } #end foreach $i
} # end mkthumb_files

sub menu_file
{
    #---------------------------------------------#
    # It creates a menu.$EXT file at 
    # the root level of the picture
    # directory (at the first 
    # directory that was passed to the script) or
    # it returns a string to be put in e/a index.$EXT file
    #
    # if there is a file named .new 
    # inside the given directory,
    # then a IMG tag will be put in 
    # front of the link with an image
    # src=myscript{new} in it
    # 
    # Thus in the config file put a line as such:
    # new=http://images.server.com/new_icon.png;
    #----------------------------------------------#

    # deprecated: init_config($ROOT_DIRECTORY);

    my $MENU_STR = ""; # return this instead of making file
    my $IMG = ""; 
    my $line = "";
    #my $this_file= "";
    my $y=0;    # counts number of td's
    my $i=0;    # general purpose counter
    my $j=0;    # count number of TR's
    my @ls = ();
    my $ts = "";
    my @files=();
    my @pixdir = (); # reset array 

    my @ary = do_dir_ary($ROOT_DIRECTORY);
    # remove duplicates:
    my %seen = ();
    my @uniq = grep(!$seen{$_}++,@ary);

    # for e/a directory here
    # check if a $SKIP_DIR_FILE file exists
    # if it does, then skip it and do the next one.
    # if it doesn't, then assume this will contain
    # a index.$EXT file and add it to the menu. 
    foreach my $directory (@uniq){
        next if (-f File::Spec->catfile($directory,$SKIP_DIR_FILE));
        next if ( basename($directory) =~ /^\./ ); # skip dir names starting with .
        # remove ./ or . from begining of names
        $directory =~ s,^\./*,,g;
        # note that @ls holds the HTML links...
        # thus, paths are relative and not absolute here:
        push( @ls,File::Spec->catfile($directory,$FILE_NAME.".".$config{$ROOT_DIRECTORY}{"ext"}) );
    }   
    dict_sort(\@ls); # sort in dictionary order
    $TOTAL_LINKS = $#ls + 1;
    # set menu-name now (from command-line or config file)
    if ( $NEW_MENU_NAME !~ /^\s*$/ ) 
    {
        $MENU_NAME=$NEW_MENU_NAME;
    } elsif ( defined($config{$ROOT_DIRECTORY}{"menuname"}) 
        and $config{$ROOT_DIRECTORY}{"menuname"} !~ /^\s*$/ )
    {
        $MENU_NAME=$config{$ROOT_DIRECTORY}{"menuname"};
    } # else MENU_NAME keeps the default name

    if ( $config{$ROOT_DIRECTORY}{"menutype"} eq "modern" )
    {
        # create modern menu 
        # modern menu is a file, no --menu-only needed here
        open(FILE, "> ".$ROOT_DIRECTORY."/".$MENU_NAME.".".$config{"$ROOT_DIRECTORY"}{"ext"}) 
            or mydie("Couldn't write file $MENU_NAME.".$config{"$ROOT_DIRECTORY"}{"ext"}." to $ROOT_DIRECTORY","menu_file");
        print FILE ($config{"$ROOT_DIRECTORY"}{"header"}."\n");
        print FILE ($config{"$ROOT_DIRECTORY"}{"table"}."\n");
        # loop
        foreach (@ls)
        {
            # no warnings;
            if ($config{$ROOT_DIRECTORY}{"tr"} =~ m/\%+bgcolor\%+/i)
            {
                my $tmp_tr = "";
                # alternate colors for TR?
                my $color = (($j % 2) == 0) ? "bgcolor=\"#efefef\"" : "" ;
                ($tmp_tr = $config{$ROOT_DIRECTORY}{"tr"}) =~ s/\%+bgcolor\%+/$color/i;
                print FILE ($tmp_tr."\n");
            } else {
                print FILE ($config{"$ROOT_DIRECTORY"}{"tr"}."\n");
            }
            if ( -f $config{$ROOT_DIRECTORY}{"albumpix"} )
            {
                print FILE ("\t<td background='".$config{"$ROOT_DIRECTORY"}{"albumpix"}."' align='center'>\n");
            } else {
                print FILE ("\t".$config{"$ROOT_DIRECTORY"}{"td"}."\n");
            }
            #if ( $ls[$i] !~ /^\s*$/ )
            #{
                # if link exists, otherwise leave it blank
                $ts = dirname($ls[$i]);
                if ( $nautilus_root gt "" ) {
                    $ls[$i] =~ s,$nautilus_root/,,g;
                    $ts =~ s,$nautilus_root/*,,g;
                }
                $IMG = ( -f File::Spec->catfile($ts,".new") ) ? 
                    "<img valign='middle' border=0 src='".
                    $config{"$ROOT_DIRECTORY"}{"new"}.
                    "' alt='new'>" : "";
                my $tmp_ts = basename("$ts");
                $tmp_ts = str_truncate($tmp_ts); # truncate up to $STR_LIMIT
                $tmp_ts = ucfirst($tmp_ts); # uppercase first letter
                my $image = "";
                if ( -d File::Spec->catfile($ts,$THUMBNAIL) )
                {
                    # get all files starting with 't' and ending in .??? 
                    # (3 characters); they might or might not be picture files, 
                    # but... we are trusting they are for now
                    my @glob_ary = glob("$ts/$THUMBNAIL/t*.???");
                    my $attempts = 3; # number of tries to get an image
                    IMAGE:
                    $image = $glob_ary[rand(@glob_ary)];
                    if ( $image !~ /$EXT_INCL_EXPR$/i 
                        or ! -f $image 
                        or $attempts != 0
                    ) { 
                        print LOGFILE "$image is not an IMAGE file\n"; 
                        $attempts--;
                        goto IMAGE;
                    }
                    my $tmp_image="";
                    if ( -f $image )
                    {
                        $tmp_image="<img src='$image' border=0 alt='$tmp_ts album'>";
                    } else {
                        $tmp_image="MISSING. Try re-running ".basename($0)." with no arguments";
                    }
                    print FILE ("\t\t<a class='pdlink' href='$ls[$i]' target='_top'>\n\t\t$tmp_image</a></td>\n\t".$config{"$ROOT_DIRECTORY"}{"td"}."\n\t\t<a class='pdlink' href='$ls[$i]' target='_top'>$IMG $tmp_ts</a>\n");
                } else {
                    print LOGFILE "$ts has no thumbnail [$THUMBNAIL] directory. Have you executed ".basename($0)." without --menu-only or --menu-type='modern' yet?";
                }
                # close table row  (TR)
                print FILE ("\t</td>\n</tr>\n");
                # TODO do we need two counters here?
                $i++; # incr file counter
                #} 
            $j++; # incr TR counter
        } # end while loop
        print FILE ("</table>\n");
        print FILE ($config{"$ROOT_DIRECTORY"}{"footer"}."\n");
        # close file
        close(FILE);

        # return a menu that contains a link back to menu.$EXT
        # Note that we use the URI here and not try to guess the relative path...
        $MENU_STR .= $config{"$ROOT_DIRECTORY"}{"table"}.
            "\n<tr>\n\t<td align='center'>\n<div align='center'>\n";
        $MENU_STR .= "\t\t<a class='pdlink' href='".
            $config{"$ROOT_DIRECTORY"}{"uri"}."/".$MENU_NAME.".".
            $config{"$ROOT_DIRECTORY"}{"ext"}.
            "'>Back to Menu</a>\n</div>\n";
        $MENU_STR .= "\t</td>\n</tr>\n</table>\n";
    } else {
        # classic is default menu type
        if ( $MENUONLY > 0 ) {
            open(FILE, "> ".$ROOT_DIRECTORY."/".$MENU_NAME.".".
                $config{"$ROOT_DIRECTORY"}{"ext"}) 
                or mydie("Couldn't write file $MENU_NAME.".
                    $config{"$ROOT_DIRECTORY"}{"ext"}.
                    " to $ROOT_DIRECTORY","menu_file");
        }

        # menus are now part of the index.EXT...
        # print header only if menuonly is set and we want to show
        # the header/footer set in .pixdir2htmlrc
        if ( $MENUONLY > 0 
            && $config{"$ROOT_DIRECTORY"}{"menuheader_footer"} > 0 )
        {
            print FILE ($config{"$ROOT_DIRECTORY"}{"header"}."\n");
        }
        # generate menu
        if ( $TOTAL_LINKS > 1 )
        {
            if ( $MENUONLY > 0 ) 
            {
                print FILE ($config{"$ROOT_DIRECTORY"}{"table"}."\n");
            }
            $MENU_STR .= $config{"$ROOT_DIRECTORY"}{"table"}."\n";
            # print all links now
            my $tmp_tr = ""; # used to color the rows
            foreach (@ls)
            {
                # temporarily turn off warnings
                no warnings;
                # TODO
                # menu only routine: prints to a file... should merge
                # with the str portion (see else)
                #
                if ( $MENUONLY > 0 ) {
                    if ($config{"$ROOT_DIRECTORY"}{"tr"}=~m/\%+bgcolor\%+/i){
                        if (($j % 2) == 0){
                            ($tmp_tr = $config{"$ROOT_DIRECTORY"}{"tr"}) =~ s/\%+bgcolor\%+/bgcolor="#efefef"/i;
                        } else {
                            ($tmp_tr = $config{"$ROOT_DIRECTORY"}{"tr"}) =~ s/\%+bgcolor\%+//i;
                        }
                        print FILE ($tmp_tr."\n");
                    } else {
                        print FILE ($config{"$ROOT_DIRECTORY"}{"tr"}."\n");
                    }
                    for ($y=1;$y<=$config{"$ROOT_DIRECTORY"}{"menutd"};$y++){
                        # close the TD tags
                        if ($y > 1) { 
                            print FILE ("\t </td> \n"); 
                        }   
                        print FILE ("\t".$config{"$ROOT_DIRECTORY"}{"td"}."\n");

                        if ( $ls[$i] ne "" ) {
                            # if link exists, otherwise leave it blank
                            $ts = dirname($ls[$i]);
                            # from nautilus one cannot pass arguments
                            # "--menuonly" but... just to keep things
                            # consistent...
                            # if number of characters is greater than $STR_LIMIT
                            # truncate $ts to a few characters.
                            if ( $nautilus_root gt "" ) {
                                $ls[$i] =~ s,$nautilus_root/,,g;
                                $ts =~ s,$nautilus_root/*,,g;
                            }
                            # remove CUT_DIRS number of directories from ts
                            if ( $CUT_DIRS > 0 ) 
                            {
                                $ts = cut_dirs($ts,$CUT_DIRS);
                            }

                            my $tmp_ts = str_truncate($ts);

                            $IMG = (-f "$ts/.new") ? "<img valign='middle' border=0 src='".$config{"$ROOT_DIRECTORY"}{"new"}."' alt='new'>":""; # if .new file
                            $ts = ucfirst($tmp_ts);
                            print FILE ("\t\t<a href='".$config{"$ROOT_DIRECTORY"}{"uri"}."/$ls[$i]' target='_top'>$IMG $ts</a>\n");
                        } else {
                            print FILE ("&nbsp;");
                        }
                        $i++;
                    } # end for $y
                    print FILE ("</tr>\n");
                    $j++; # incr TR counter
                } else {
                    # general menu routine
                    # TODO cleanup
                    if ($config{"$ROOT_DIRECTORY"}{"tr"}=~m/\%+bgcolor\%+/i){
                        if (($j % 2) == 0){
                            ($tmp_tr = $config{"$ROOT_DIRECTORY"}{"tr"}) =~ s/\%+bgcolor\%+/bgcolor="#efefef"/i;
                        } else {
                            ($tmp_tr = $config{"$ROOT_DIRECTORY"}{"tr"}) =~ s/\%+bgcolor\%+//i;
                        }
                        $MENU_STR .= $tmp_tr."\n";
                    } else {
                        $MENU_STR .= $config{"$ROOT_DIRECTORY"}{"tr"}."\n";
                    }
                    for ($y=1;$y<=$config{"$ROOT_DIRECTORY"}{"menutd"};$y++){
                        # close the TD tags
                        if ($y > 1) { 
                            $MENU_STR .= "\t </td> \n";
                        }   
                        $MENU_STR .= "\t".$config{"$ROOT_DIRECTORY"}{"td"}."\n";
                        # menu entries
                        if ( $ls[$i] ne "" ) {
                            # if link exists, otherwise leave it blank
                            $ts = dirname ($ls[$i]);
                            $IMG = (-f "$ts/.new") ? "<img valign='middle' border=0 src='".$config{"$ROOT_DIRECTORY"}{"new"}."' alt='new'>":""; # if .new file
                            # if number of characters is greater than $STR_LIMIT
                            # truncate $ts to a few characters.
                            if ( $nautilus_root gt "" ) {
                                $ls[$i] =~ s,$nautilus_root/,,g;
                                $ts =~ s,$nautilus_root/*,,g;
                            }
                            # remove CUT_DIRS number of directories from ts
                            if ( $CUT_DIRS > 0 ) 
                            {
                                $ts = cut_dirs($ts,$CUT_DIRS);
                            }
                            my $tmp_ts = str_truncate($ts);
                            $ts = ucfirst($tmp_ts);
                            # $ls tends to hold the whole filename path+filename
                            # we don't care about the whole path here...
                            $MENU_STR .= "\t\t<a href='".
                                $config{"$ROOT_DIRECTORY"}{"uri"}.
                                "/$ls[$i]' target='_top'>$IMG $ts</a>\n";
                        } else {
                            $MENU_STR .= "&nbsp;";
                        }
                        $i++;
                    } # end for $y
                    $MENU_STR .= "</tr>\n";
                    $j++; # incr TR counter
                } # end if/else menuonly
            }
            if ( $MENUONLY > 0 ) {
                print FILE ("</table>\n");
            }
            $MENU_STR .= "</table>\n";
        # end if TOTAL_LINKS
        } else {
            print $LOGFILE (": Not a single link found\n");
        }
        # see previous notes on header
        if ( $MENUONLY > 0 
            && $config{"$ROOT_DIRECTORY"}{"menuheader_footer"} > 0)
        {
            print FILE ($config{"$ROOT_DIRECTORY"}{"footer"}."\n");
        } 
        if ( $MENUONLY > 0 ) {
            close(FILE);
        }
    }
    if ( $TOTAL_LINKS > 1 ) {
        print $LOGFILE (": $TOTAL_LINKS links in menu.\n");
    }
    return $MENU_STR;
} #end menu_file

# ---- HELPER functions ----- #

sub str_truncate 
{
    my $str = shift;
    my $str_length = length ($str);
    $str = ($str_length > $STR_LIMIT) ? "...".substr($str,($STR_LIMIT/2),$str_length):$str;
    # return truncated string
    return $str;
} #end str_truncate

sub progressbar
{
    my ($PROGRESS,$TOTAL)=@_;
    chomp($PROGRESS);
    chomp($TOTAL);
    my $current = 0;
    # make sure we don't divide by 0
    if ( $TOTAL > 0 ) 
    {
        $current = sprintf( "%02d",($PROGRESS/$TOTAL) * 100 );
        if ( $use_console_progressbar == 1)
        {
            $GAUGE->update($current);
        } else {
            print $GAUGE $current."\n";
        }
    } 
} # end progressbar

sub progressbar_msg
{
    my ($MESSAGE) = @_;

    chomp($MESSAGE);
    if ( $use_console_progressbar != 1)
    {
        print $GAUGE  "XXX\n".$MESSAGE."\nXXX\n";
    }
} # end progressbar_msg

sub do_dir_ary {
    # uses find() to recur thru directories
    # returns an array of directories
    # i.e. in directory "a" with structure:
    # /a
    # /a/b
    # /a/b/c
    # /a/b2/c2
    # 
    # my @ary = &do_dir_ary(".");
    # 
    # will yield:
    # a
    # a/b
    # a/b/c
    # a/b2/c2
    # 

    my $ROOT = shift;
    my %opt = (wanted => \&process_dir, no_chdir=>1);
    find(\%opt,$ROOT);
    return @pixdir;
} # end do_dir_ary

sub process_dir {
    my $base_name = basename ($_);
    if  ( 
        -d $_ 
        && ! -f "$_/$SKIP_DIR_FILE"
        && $base_name !~ m/^($EXCEPTION_LIST)$/
        && $base_name !~ m/\b$THUMBNAIL\b/
        && $base_name !~ m/\b$HTMLDIR\b/
        && $base_name !~ m/^\.[a-zA-Z0-9]+$/ 
        ) 
    {
        push @pixdir,$_;
    }
} # end process_dir

sub do_file_ary {
    # uses find() to recur thru directories
    # returns an array of files
    # i.e. in directory "a" with the files:
    # /a/file.txt
    # /a/b/file-b.txt
    # /a/b/c/file-c.txt
    # /a/b2/c2/file-c2.txt
    # 
    # my @ary = &do_file_ary(".");
    # 
    # will yield:
    # a/file.txt
    # a/b/file-b.txt
    # a/b/c/file-c.txt
    # a/b2/c2/file-c2.txt
    # 
    my $ROOT = shift;
    my %opt = (wanted => \&process_file, no_chdir=>1);
    find(\%opt,$ROOT);
    return @pixfiles;
} # end do_file_ary

sub process_file {
    my $base_name = basename($_);
    my $dir_name = dirname ($_);
    if  ( 
        -f $_
        && ! -f "$dir_name/$SKIP_DIR_FILE"
        && $base_name =~ m/$EXT_INCL_EXPR$/i # only pictures please
        && $base_name !~ m/^($EXCEPTION_LIST)$/
        && $base_name !~ m/\b$THUMBNAIL\b/
        && $base_name !~ m/\b$HTMLDIR\b/
        && $base_name !~ m/^\.[a-zA-Z0-9]+$/ # skip dot files
        ) 
    {
        s/^\.\/*//g;
        push @pixfiles,$_;
    }
} #end process_file

sub cut_dirs {
    # call like cut_dirs($ts,$CUT_DIRS);
    # where ts is a path in the form "path/to/something"
    # and $CUT_DIRS is an integer
    my $path = shift;
    my $cut = shift;
    # TODO is there a way to know the OS separator string in Perl
    # a la Python?
    $path =~ s,^/,,g; # remove leading slashes
    my @tmp_path = split(/\//,$path);
    my $tmp_str = "";

    for ( my $i = 0; $i <= $#tmp_path; $i++ )
    {
        if ( $i >= $cut ) # to be safe, display the last name
        {
            $tmp_str .= $tmp_path[$i]."/";
        }
    }
    return $tmp_str;
} # end cut_dirs

sub dict_sort
{
    # sort menus alphabetically (dictionary order):
    #@param 0 array_ref := array to sort
    #@param 1 string/pattern := what to ignore [optional]
    my $aryref = shift;
    my $ignore = shift;

    #open(UNSORTED,">unsorted.txt");
    #print UNSORTED join(' ', @$aryref), "\n";
    #close(UNSORTED);

    my $da;
    my $db;

    if ( $ignore ne "" )
    {
        # TODO what's the best way to ignore this pattern?
        #        my @local_ls;
        #        my $i = 0;
        #        foreach( @$aryref )
        #        {
        #            ( $local_ls[$i] = $_ ) =~ s/$ignore//g;
        #            $i++;
        #        }
        @$aryref = sort { 
            # TODO ignore here?
            ($da = lc $a) =~ s/[\W_]+//g;
            ($db = lc $b) =~ s/[\W_]+//g;
            $da cmp $db;
        } @$aryref;
    } else {
        @$aryref = sort { 
            ($da = lc $a) =~ s/[\W_]+//g;
            ($db = lc $b) =~ s/[\W_]+//g;
            $da cmp $db;
        } @$aryref;
    }
} # end dict_sort()

sub mydie
{
    # @param 0 string := message to log
    # @param 1 string := function which called us
    my $msg = shift;
    my $fun = shift;
    print LOGFILE "DIE: $fun : $msg\n";
    die("Stopping execution $fun");
}

#-------------------------------------------------#
#                 DOCUMENTATION                   #
#-------------------------------------------------#
__END__

=head1 NAME

pixdir2html - makes thumbnails and custom html files for pictures

=head1 SYNOPSIS

B<pixdir2html.pl>  [-n,--no-menu]
                [-N,--no-index]
                [-f,--force] 
                [-M,--menu-only]
                [-E,--extension] 
                [-t,--thumbs-only]
                [-D,--directory] 
                [-l,--menu-links,--menu-td]
                [-m,--menu-type=[classic,modern]]
                [--menu-name=[menu]]
                [-c,--cut-dirs]
                [-F,--front-end=[Xdialog,zenity,console,...]]
                [--td]
                [--str-limit]
                [-h,--help]

=head1 DESCRIPTION 

For the Impatient:
    Passes current directory to script 
    shell> pixdir2html.pl 
    
    Force copies the "rootdir"/.pixdir2htmlrc
    to all other directories within this tree
    shell> pixdir2html.pl -f --directory="rootdir"
    
    To use this script in a non interactive way with Nautilus,
    make this file executable and put it in:
        ~/.gnome2/nautilus-scripts

    Then run it from from the File->Scripts menu in Nautilus

=head1 OPTIONS

=over 8

=item -n,--no-menu

do not create menu file after finishing creating thumbnails

=item -N,--no-index

do not create the index.EXT files after creating thumbnails

=item -f,--force

copy the .pixdir2htmlrc file from rootdir in every subdirectory

=item -M,--menu-only

only create a menu file and exit

=item -E,--extension 

extension to use for output files. Defaults to "html"

=item -t,--thumbs-only

generate thumbnail files only in thumbnail directory. Defaults to "t"

=item -D,--directory

directory containing all pictures to work with. Defaults to "."

=item -l,--menu-links,--menu-td

number of links to put in the Menu per row in classic menus. Default is 10

=item -m,--menu-type=[classic,modern]

menu type to use for albums (directories).
    Classic uses plain text menus.
    Modern lays menus vertically with a sample thumbnail and their name

=item --menu-name=[index]

name to use for menu files. Defaults to "menu"

=item -c,--cut-dirs

number of directories to cut from the classic Menu string. Default is 0

=item -F,--front-end=[Xdialog,zenity,console,...]

dialog to use to display progress. Must be compatible with Xdialog
or you can also choose "console" if you have Term::ProgressBar 
installed. Defaults to Zenity for Nautilus

=item --td

number of cells in e/a index file for classic Menus

=item --str-limit

size of the longest string allowed in menus. Defaults to unlimited

=item -h,--help

prints this help and exit

e.g.

cd /path/to/picture_directory

pixdir2html --extension="php"

is the same as:

pixdir2html -E php
 
You could customize each directory differently by having a
file named .pixdir2htmlrc in the directory containing the
pictures. Put a .nopixdir2htmlrc file in directories for which 
you do not want thumbnails and/or index.$EXT to be written. A
sample .pixdir2htmlrc should have the following:

uri=http://absolute.path.com/images # must be absolute. no trailing /

header=

percent=30% #size of the thumbnails for this folder

title=

meta=

stylesheet=http://absolute.path.com/styles/styles.css

html_msg=<h1 class="pdheader1">Free form using HTML tags</h1> 

body=<body bgcolor="#000000" class="pdbody">

p=<p class="pdparagraph">

table=<table border="0" class="pdtable">

td=<td valign="left" class="pdtd">

tr=<tr %%bgcolor%% class="pdtr">

new=http://absolute.path.com/images/new.png # for dirs with .new files

footer=<a href="#" class="pdlink">A footer here</a>

# set this to 1 to avoid printing a header

# or footer in the menu file menu.$EXT

menuheader_footer=0

ext=html

menutype=classic

# full path to a picture which will be used as the background image 

# for the album icons. album"s thumbnails must be exactly the 

# same size for this to look good.

albumpix=album.png  

A simple styles.css file should have things like:

.pdimage {
  border: 0;
}

.pdbody { 
  font-family: Verdana, Lucida, sans-serif;
  color: #ce7500;
  text-decoration: none;
  background: #ffffff;
  background-image: url("/path/to/images/image.png"); 
  background-repeat: no-repeat;
  background-attachment: fixed;
  background-position: center;
}

.pdtd {
  vertical-align: top;
  padding: 2px 0px 0px 0px;
  font-family : "hoefler text", Tahoma, Helvetica, sans-serif;
  font-size : 11pt;
  color : #000000;
  text-decoration : none;
  background-color: transparent;
}

.pdtr {}

.pdparagraph {}

.pdtable {}

.pdlink a {
  vertical-align: top;
  padding: 2px 0px 0px 0px;
  color:  #7090A6;
  background-color: transparent;
  font-weight: bold;
  text-decoration:    none;
}

.pdlink a:visited  {
  vertical-align: top;
  padding: 2px 0px 0px 0px;
  text-decoration:    none;
  font-weight: bold;
  color:  #7090A6;
  background-color: transparent;
}

.pdlink a:hover {
  vertical-align: top;
  padding: 2px 0px 0px 0px;
  background-color: transparent;
  font-weight: bold;
  color:  #7090A6;
  text-decoration:    none;
}

=back

=head1 ENVIRONMENT

No environment variables are used.

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=head1 SEE ALSO

perl(1), pod2man(1), Image::Magick(3), Term::Progressbar(3)

=cut

