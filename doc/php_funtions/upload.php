<?php
    error_reporting(E_ALL);
    /* NOTES:
     * Copy this script in a directory, say "images"
     * and make sure that a directory named "tmp"
     * exists inside images.
     *
     * Then from a browser call this script as:
     * http://www.server.com/images/upload.php
     *
     */
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<HTML>
<HEAD>
<TITLE>Simple File Upload Form</TITLE>
</HEAD>
<BODY bgcolor="white">

<?php
/*
 * $Revision: 1.1 $
 *
 * Last modified: 2003-Oct-24
 */

$DEBUG = true;

$file_type="\.gif$|\.png$|\.j[e]*pg";
$path="tmp/";

$binary_tmpname = $_FILES['photo_upload']['tmp_name'];
$binary_filesize = $_FILES['photo_upload']['size']; 
$binary_basename = $_FILES['photo_upload']['name'];

$binary_filename = $path.$binary_basename; // local file in server


if ( $send == "Send" ) { echo "<font color='green'>File sent... testing validity</font><br>"; }

//$binary_junk = addslashes(fread(fopen($_FILES['photo_upload']['tmp_name'], "r"), $_FILES['photo_upload']['size']));
if ( $send == "Send" && preg_match("/$file_type/i",$_FILES['photo_upload']['name']) ) 
{

    if ( move_uploaded_file($binary_tmpname,$binary_filename) ) 
    {
        echo "<font color='green'>File $binary_basename ".
            "($binary_filesize) uploaded sucessfully</font><br>";
        echo "To use this image refer to it as:<br>".
            "<b>&lt;img src'/images/$binary_filename'&gt;</b><br>";
        echo "<br><img src='/images/$binary_filename'><br>";
        echo "<br>To see all images <a href='$path'>click here</a><br>";
    } else {
        echo "<br><font color='red'>Upload could not be completed. ".
        "Please contact system administrator: ".
        "<a href='mailto:webmaster at latinomixed . com'>".
        "webmaster at latinomixed.com</a><br>".
        "Error Code: ".$_FILES['photo_upload']['error']."</font><br>";
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
<form name="file_upload" action="upload.php" enctype="multipart/form-data" method="post">
<input type="hidden" name="MAX_FILE_SIZE" value="2000000">
File to upload (*.jpg, *.gif, *.png only):<br>
<input type="file" name="photo_upload" size="32" maxlength="255">
<input type="submit" name="send" value="Send">
</form>

</BODY>
</HTML>

