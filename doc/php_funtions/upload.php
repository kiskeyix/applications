<?php
error_reporting(0);
/* NOTES:
 * Copy this script in a directory, say "images"
 * and make sure that a directory named "tmp"
 * exists inside images.
 *
 * Then from a browser call this script as:
 * http://www.server.com/images/index.php
 *

 * $Revision: 1.4 $
 *
 * Last modified: 2004-Oct-28
 */

$DEBUG = true;

$my_domain = "domain.com";

$send = (! empty($send) ) ? $send : "";

$path="tmp/"; // where files will be uploaded. relative to our script
            // and publicly visible from the web

$common_private_networks = "192.168. 10."; // space separated list

/* content of the $path/.htaccess file */
$htaccess_content = "Order deny,allow\nDeny from all\nAllow from localhost .$my_domain $common_private_networks \n";

//$file_mode="0664"; // rw-rw-r -> 0664; rw-r-r -> 0644
$file_type="\.gif$|\.png$|\.j[e]{0,1}pg$|\.[g]{0,1}zip$|\.gz$|\.dwg$|\.doc$|\.xls$|\.pps$";

$binary_tmpname = $_FILES['upload']['tmp_name'];
$binary_filesize = $_FILES['upload']['size']; 
$binary_basename = $_FILES['upload']['name'];


/* Make directory $path */
if (! file_exists($path) 
    && ! is_dir($path) ) 
{ 
    umask(000);
    mkdir($path,0777); 
}

/* This would be nice if .htaccess is not allowed... see below
 *
if ( ! file_exists("$path/index.html") )
{
    touch("$path/index.html"); // if users attempt to go to $path
                            // they will see a blank window
}
*/

if (! file_exists("$path/.htaccess") ) {
    if ( ! $tmp_file = fopen("$path/.htaccess","w+") )
    {
        echo "Could not create .htaccess\n";
        // exit;
    }
    /* write protection to directory $path */
    if ( fwrite($tmp_file,$htaccess_content) === FALSE ) 
    {
        echo "Could not write content to .htaccess\n";
        /* users get a blank list then */
        touch("$path/index.html");
        // exit;
    }
    fclose($tmp_file);
}

$binary_filename = $path."/".$binary_basename; // local file in server

echo "
<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2//EN\">
<HTML>
<HEAD>
<TITLE>Simple File Upload Form [$my_domain]</TITLE>
</HEAD>
<BODY bgcolor=\"white\">
";

if ( $send == "Send" ) { 
    echo "<font color='green'>File sent... testing validity</font><br>"; 
}

//$binary_junk = addslashes(fread(fopen($_FILES['upload']['tmp_name'], "r"), $_FILES['upload']['size']));
if ( $send == "Send" 
    && preg_match("/$file_type/i",$_FILES['upload']['name']) ) 
{
    if ( move_uploaded_file($binary_tmpname,$binary_filename) ) 
    {
        // do not complaint if this is not possible
        //@chmod("$binary_filename","$file_mode");
        echo "<font color='green'>File $binary_basename ".
            "($binary_filesize) uploaded sucessfully</font><br>";
        echo date("r")."<br>";
        //echo "To use this image refer to it as:<br>".
        //    "<b>&lt;img src='/images/$binary_filename'&gt;</b><br>";
        // echo "<br><img src='/images/$binary_filename'><br>";
        //echo "<br>To see all images <a href='$path'>click here</a><br>";
    } else {
        echo "<br><font color='red'>Upload could not be completed. ".
        "Please contact system administrator: ".
        "<a href='mailto:webmaster at rbsd . com'>".
        "webmaster at rbsd.com</a><br>".
        "Error Code: ".$_FILES['upload']['error']."</font><br>";
        if ( $DEBUG )
        {
            echo "Ary: ";
            print_r($_FILES);
            echo "<br><br>";
        }
    }
} else {
    // sanity
    if ( !empty($binary_basename) )
    {
        // file didn't have the right extension?
        echo "<br><font color='red'>Invalid file".
        $binary_basename.
        "</font><br>";
        echo "All files must have .jpg, .gif or .png extensions".
        "<br><b> Example of a good filename: my_vacation.jpg</b>".
        "<br><br>Please rename your file and try again <br>";
    }
    echo "Please choose file to upload<br>";
}
?>
<br>
<form name="file_upload" action="index.php" enctype="multipart/form-data" method="post">
<input type="hidden" name="MAX_FILE_SIZE" value="25000000">
File to upload (*.zip, *.gz, Autocad files, Microsoft Office files or images only):<br><br>
<input type="file" name="upload" size="32" maxlength="255">
<input type="submit" name="send" value="Send">
</form>
</BODY>
</HTML>
