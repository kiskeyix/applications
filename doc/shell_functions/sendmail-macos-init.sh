#! /bin/sh
# Restarts sendmail after redoing the config file
if [ /etc/mail/config.mc -nt /etc/mail/sendmail.cf ]
then
    echo "Regenerating sendmail.cf"
    m4 /usr/share/sendmail/conf/m4/cf.m4 /etc/mail/config.mc > \
        /tmp/sendmail.cf
    mv /etc/mail/sendmail.cf /etc/mail/sendmail.cf.old.$$$$
    mv /tmp/sendmail.cf /etc/mail/sendmail.cf
    /System/Library/StartupItems/Sendmail/Sendmail restart
fi

