<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<?php/*
* Written by Luis Mondesi for Events Digital
* Oct 17, 2001
*/
// this function checks for email validity. returns 1 if true or 0 otherwise
function valid_email($EMAIL) {
	if (ereg('^[-!#$%&\'*+\\./0-9=?A-Z^_`a-z{|}~]+'. '@'. '[-!#$%&\'*+\\/0-9=?A-Z^_`a-z{|}~]+\.' . '[-!#$%&\'*+\\./0-9=?A-Z^_`a-z{|}~]+$', $EMAIL)){
		return 1;
	} else {
		return 0;
	}
}
if (!isset($HTML_MESSAGE)){
	$HTML_MESSAGE="";
}// modify this to point to right email
$HELP_EMAIL = "help@eventsdigital.com";

// other headers$extras = "From: $HELP_EMAIL \nReply-to: $HELP_EMAIL";

// success message
// errors vary according to input, but success is always the same:
$HTML_SUCCESS="<font color='green'><p>Message sent successfully!</p><p>You may <a href='javascript:window.close();'>close this window now</a></p></font>";

if ($sender == '') {
	$submit = 0;
	$HTML_MESSAGE .= "<p><font color='red'>Sender email must be set before submitting</font></p>";
} else {
	if (valid_email($sender)){
		$submit=1;
	} else {
		// user used the wrong email address
		$HTML_MESSAGE.="<p><font color='red'>Sender email is wrong. Please provide a valid email address first</font></p>";
		$submit=0;
	}
}
if ($submit) {
// sender email was verified, we need to worry about other fields, such as $user and $subject for slashes... (back slashes) and also, $message
// password could basically be anything
$user = stripslashes($user);
$subject = stripslashes($subject);

$mymessage = "User: $user \n Password: $passwd \n Sender: $sender \n Subject: $subject \n \n";
$mymessage = $mymessage."\n".stripslashes($message);
	    if ($cc == 1) {
            // separated by commas. send a copy to sender
            $NEW_EMAIL = $HELP_EMAIL.",".$sender;		
            if (mail($NEW_EMAIL,$subject,$mymessage,$extras)){			
                $HTML_MESSAGE=$HTML_SUCCESS;		
            } else {			
                $HTML_MESSAGE="<p><font color='red'>Message could not be sent</font></p>";		
            }
	} else {
		if (mail($HELP_EMAIL,$subject,$mymessage,$extras)){
			$HTML_MESSAGE=$HTML_SUCCESS;		} else {
			$HTML_MESSAGE="<p><font color='red'>Message could not be sent</font></p>";		}
	}
}
?>
<html>

	<head>
		<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
		<title>Help Email</title>
	</head>

	<body bgcolor="#ffffff">
	<?php
		echo $HTML_MESSAGE;
	?>
		<form name="help_email" action="help.php3" method="post">
			User: <input type="text" name="user" size="24" maxlength="255" value="<?php echo stripslashes($user) ?>"> Password: <input type="password" name="passwd" size="24" maxlength="24">
			<p>Sender: <input type="text" name="sender" size="32" maxlength="255" value="<?php echo stripslashes($sender) ?>"> <input type="checkbox" value="1" name="cc" <?php echo $checked = ($cc == 1) ? "checked" : "" ; ?> > Send me a copy</p>
			<p>Subject: <input type="text" name="subject" size="72" maxlength="255" value="<?php echo stripslashes($subject) ?>"></p>
			<p><textarea name="message" cols="77" rows="12"><?php echo stripslashes($message) ?></textarea></p>
			<div align="left">
				<p><input type="submit" name="submit" value="Send">  <input type="reset"></p>
			</div>
		</form>
		<p></p>
	</body>

</html>
