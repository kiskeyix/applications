#!/bin/sh

create_cert()
{
	cert=$1
	description=$2
	echo "Creating generic self-signed certificate: /etc/ssl/certs/$cert.pem"
	echo "(replace with hand-crafted or authorized one if needed)."
	
	HOSTNAME=mail.kiskeyix.org
	FQDN=mail.kiskeyix.org
	MAILNAME=`cat /etc/mailname || hostname -f`
	openssl req -new -x509 -days 365 -nodes -out "$cert.pem" -keyout "$cert.pem" > /dev/null 2>&1 <<+
.
.
.
$description
$HOSTNAME
$FQDN
webmaster@$MAILNAME
+
	ln -sf "$cert.pem" `openssl x509 -noout -hash < "$cert.pem"`.0
	chown root.root "/etc/ssl/certs/$cert.pem"
	chmod 0640 "/etc/ssl/certs/$cert.pem"
}

create_cert ipop3d "University of Washington POP3 daemon"
sleep 1
create_cert imapd "University of Washington IMAP daemon"

