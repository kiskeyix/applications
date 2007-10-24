#!/usr/bin/perl -w
# $Revision: 1.7 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: Adds user to ldap server running on (tls)
# ldap://$LDAPSERVER:389
# This is NOT a POSIX user, just a regular user to allow chatting
#
# This is a modified version of my original script, adduser-ldap.pl
# http://lems.kiskeyix.org/toolbox/?f=adduser-ldap.cgi
# USAGE: from browser
# LICENSE: GPL
###

use strict;
$|++;    # disable buffer (autoflush)

eval "use Net::LDAP";
if ($@)
{
    print STDERR "\nERROR: Could not load the Net::LDAP module.\n"
      . "       To install this module use:\n"
      . "       Use: perl -e shell -MCPAN to install it.\n"
      . "       On Debian just: apt-get install libnet-ldap-perl \n\n"
      . print STDERR "$@\n";
    exit 1;
}
eval "use CGI qw/:cgi/";
if ($@)
{
    print STDERR "\nERROR: Could not load the CGI module.\n"
      . "       To install this module use:\n"
      . "       Use: perl -e shell -MCPAN to install it.\n"
      . "       On Debian just: apt-get install perl-modules \n\n"
      . print STDERR "$@\n";
    exit 1;
}
eval "use Net::SMTP";
if ($@)
{
    print STDERR (
                  "\nERROR: Could not load the Net::SMTP module.\n",
                  "       To install this module use:\n",
                  "       perl -e shell -MCPAN.\n",
                  "       On Debian just: apt-get install libnet-smtp-perl \n\n",
                  "\n"
                 );
    exit 1;
}

my $DEBUG = 0;

my $CHATSERVER = "chat.example.com";
my $LDAPADMINCN =
  "uid=cadmin,ou=Administrators,ou=TopologyManagement,o=netscapeRoot";
my $LDAPPASSWORDFILE = "/etc/adduser-ldap.secret";
my $LDAPCACERT       = '/etc/ldap/cacerts/CERT';
my $LDAPSERVER       = "chat.example.com";
my $OU               = "People";
my $DOMAIN           = "example.com";

my $PASS_SCHEME = "{crypt}";

my $MAILHOST = "localhost";                              # use this mail server
my $FROM     = "Accounts\@example.com";
my $CC       = "support\@example.com";
my $SUBJECT  = "$CHATSERVER Account";
my $TIMEOUT  = 90;                                       # smtp timeout
my $TEMPLATE_MESSAGE = <<EOF;
Hello \@firstname\@,

Your $CHATSERVER account is:

User Name:  \@username\@\@$CHATSERVER
Password:   \@password\@
Server:     $CHATSERVER
Port:       5222
Protocol:   XMPP

** TLS Encryption is required **

Notes:
* Do not share your password with anybody
* Clients that are known to work

    - Pidgin: http://pidgin.im/pidgin/download  (Officially supported)
    - Exodus: http://www.jabberstudio.org/projects/exodus/releases/ (Deprecated. Use at your own risk)

* To search for other users, use the server "search.$CHATSERVER"
EOF

# ------------------------------------------------------------------- #
#                   DO NOT MODIFY BELOW THIS LINE                     #
# ------------------------------------------------------------------- #

my $html = new CGI;

# these fields will be normalized to lowercase lc() and no extra chars ( anything not matching
# /[[:alnum:]]/ ) will be removed.
#
# Note that "domain" was explicitly left out
my @fields = (
              "First Name*", "Last Name*", "User Name*", "Password",
              "E-Mail*",     "Telephone"
             );

my $intro = <<EOF;
<pre class='code'>
<center><b>Manage $CHATSERVER Users</b></center>

This form is used to create new accounts for $DOMAIN
Chat server or for reseting passwords to existing users.

Details on how to configure the chat client will be sent to the user when
this form is completed.

Users should archive the email they receive as they have no way to change
their own passwords.

When creating accounts:

- fields marked with an asterisk (*) are required
- if password is left blank, one will be generated and emailed to the user
- a message will be sent to the E-Mail address provided
- the email will be shown as coming from: $FROM
- the email subject will be: $SUBJECT

When reseting passwords:

- if the user account does not exists, the account will not be created
- if the password field is left blank, a password will be generated
- a message will be sent to the E-Mail address provided

When deleting accounts:

- delete takes precedence over 'reset'
- only User Name is needed
- this will not delete POSIX accounts

</pre>
EOF

my $style = <<EOF;
.code {
    background-color: lightyellow;
    width: 70%;
}
.smalltext {
        font-size: 8pt;
        font-family: sans-serif;
}
.errortext {
        font-size: 10pt;
        font-family: sans-serif;
        color: red;
}
.debugtext {
        font-size: 14pt;
        font-family: sans-serif;
        color: red;
}
.successtext {
        font-size: 10pt;
        font-family: sans-serif;
        color: green;
}

/* structural blocks */

#intro {
    margin-left: 50px; 
}
#form {
    margin-left: 50px; 
}
#statusblock {
    margin-left: 700px; 
    position: absolute; 
    bottom: 0px; 
    right: 0px;
}
EOF

my $jscript = <<EOF;
    
    function update_subject(element)
    {
        document.form1.subject.value = element.options[element.selectedIndex].text;
        document.form1.submit();
    }

    function update_form(element)
    {
        var fname = document.form1.firstname.value;
        var lname = document.form1.lastname.value;

        if (document.form1.email)
        {
            document.form1.email.value = fname + '.' + lname + '\@example\.com';
        }
        if (document.form1.firstname)
        {
            document.form1.firstname.value = fname;
        }
        if (document.form1.lastname)
        {
            document.form1.lastname.value = lname;
        }
        if (document.form1.username)
        {
            var uname = fname.substring(0,1) + lname;
            if (document.form1.username.length > 1)
            {
                for (i=0;i<document.form1.username.length;i++)
                {
                    document.form1.username[i].value = uname;
                }
            } else {
                document.form1.username.value = uname;
            }
        }
    }

    function reset_form()
    {
        for (i=0;i<document.form1.elements.length;i++)
        {
            if (document.form1.elements[i].type == "text")
            {
                document.form1.elements[i].value = "foo";
            }
        }
    }

EOF

# helper functions

sub print_form
{
    print "<div id='intro'>";
    print $intro;
    print "</div>";

    print "<div id='form'>";
    print $html->start_form('-name'   => "form1",
                            '-action' => "/cgi-bin/adduser-ldap.cgi");
    print $html->start_table(), "\n";
    foreach (@fields)
    {
        my $_f = lc($_);
        $_f =~ s/[^[:alnum:]]//g;
        print STDOUT ($html->start_Tr(), "\n", $html->td($_ . ': '), "\n",);
        if ($_f eq "username" or $_f eq "email")
        {

            # allows changing of username (see javascript code)
            print $html->td($html->textfield('-name' => $_f));
        }
        else
        {
            print $html->td(
                            $html->textfield(
                                             '-name'       => $_f,
                                             '-onkeypress' => "update_form()",
                                             '-onchange'   => "update_form()"
                                            )
                           );
        }
        print $html->end_Tr();
    }
    print $html->end_table();
    print $html->p({'-class' => 'smalltext'},
                   "Sample password: " . random_password(8));
    print($html->p(
                   $html->checkbox(
                                   '-name'  => 'password_reset',
                                   '-label' => "Password Reset"
                                  )
                  ),
          $html->p(
                   $html->checkbox(
                                   '-name'  => 'delete_user',
                                   '-label' => "Delete User"
                                  )
                  ),
          "\n"
         );
    print $html->reset() . " " . $html->submit() . "\n";
    print $html->end_form();
    print "</div>";
}

sub random_password
{
    my $num = shift;
    if ($num !~ /^[[:digit:]]+$/ or $num < 8)
    {
        $num = 8;
    }
    my $count          = $num;
    my @password_chars = ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z');
    my $_password      = undef;
    for (1 .. $count)
    {
        $_password .= (@password_chars)[rand(@password_chars)];
    }
    return $_password;
}

sub hash_password
{
    my $str  = shift;
    my $hash = "x";
    if (${PASS_SCHEME} =~ /crypt/i)
    {

        # generates an MD5 sum salted password with 8 random chars
        $hash = crypt($str, "\$1\$" . random_password(8) . "\$");
    }
    return $hash;
}

sub _create_entry
{
    my ($ldap, $dn, $whatToCreate) = @_;
    if ($DEBUG)
    {
        print "DEBUG: _create_entry <pre>";
        print("dn: ", $dn, "\n");
        foreach (@$whatToCreate)
        {
            print($_, "\n");
        }
        print "</pre>";
    }
    my $result = $ldap->add($dn, 'attr' => [@$whatToCreate]);
    return $result;
}

# @param whatToModify a hashref like " userPassword => 'foo' "
sub _modify_entry
{
    my ($ldap, $dn, $whatToModify) = @_;
    my $result = $ldap->modify($dn, 'replace' => {%$whatToModify});
    return $result;
}

sub _ldap_search
{
    my ($ldap, $searchString, $attrs, $base) = @_;

    # if they dont pass a base... set it for them
    if (!$base)
    {
        $base =
          ($OU) ? "ou=$OU, dc=example, dc=com" : "dc=example, dc=com";
    }

    # if they dont pass an array of attributes...
    # set up something for them
    if (!$attrs) { $attrs = ['cn', 'mail']; }
    my $result =
      $ldap->search(
                    'base'   => $base,
                    'scope'  => "sub",
                    'filter' => $searchString,
                    'attrs'  => $attrs
                   );
    return $result;
}

sub _reset_password
{
    my ($user, $password) = @_;
}

sub _get_password
{
    my $file = shift;
    if (-r $file)
    {
        open(PW, "<$file") or die("Could not read file $file. " . $!);
        undef $/;    # slurp mode
        my $content = <PW>;
        $content =~ s/(\r|\n)//g;
        return $content;
    }
    else
    {
        die("Could not read password file $file\n");
    }
}

sub _send_email
{
    my $email = shift;

    # sanity check:
    my $MAILHOST =
      (exists $email->{'mailhost'} and $email->{'mailhost'} !~ /^\s*$/)
      ? $email->{'mailhost'}
      : "localhost";
    my $FROM =
      (exists $email->{'from'} and $email->{'from'} !~ /^\s*$/)
      ? $email->{'from'}
      : $ENV{'USER'};
    my $CC =
      (exists $email->{'cc'} and $email->{'cc'} !~ /^\s*$/)
      ? $email->{'cc'}
      : "";
    my $TIMEOUT =
      (exists $email->{'timeout'} and $email->{'timeout'} !~ /^\s*$/)
      ? $email->{'timeout'}
      : 90;

    # create object
    my $smtp = Net::SMTP->new($MAILHOST, 'Timeout' => $TIMEOUT);
    $smtp->mail($FROM);

    # TODO validate $to address?
    my $_to = (exists($email->{"to"})) ? $email->{"to"} : $ENV{'USER'};

    $smtp->to($_to);
    $smtp->cc($CC) if ($CC ne "");

    $smtp->data();
    $smtp->datasend("To: $_to\n");
    my $_subj = (exists($email->{"subject"})) ? $email->{"subject"} : "";
    $smtp->datasend("Subject: $_subj\n");
    my $_msg = (exists($email->{"message"})) ? $email->{"message"} : "";
    $smtp->datasend("$_msg\n");
    $smtp->datasend();

    $smtp->quit;
}

sub _debug
{
    my $str = shift;
    print "<p class='debugtext'>$str</p>\n" if ($DEBUG);
}

# end helper functions

# main ()
print $html->header();
print $html->start_html(
                        '-title'  => "New $CHATSERVER account",
                        '-script' => $jscript,
                        '-style'  => {
                                     '-src'  => "/styles/styles.css",
                                     '-code' => $style
                                    }
                       );

# web form to ask for what to do
print_form();

# handle POST
if ($html->param())
{

    # start local variables

    my $ldap = Net::LDAP->new($LDAPSERVER);

    # TODO make sure we have the right access level to read
    # cafile below!
    #$ldap->start_tls('cafile' => $LDAPCACERT);

    my $domain       = $DOMAIN;                # if (!$html->params('domain'));
                                               # set some internal vars:
    my @domain_parts = split(/\./, $domain);

    my $domain_joined = "";
    foreach (@domain_parts)
    {
        $domain_joined .= "dc=$_, ";
    }
    $domain_joined =~ s/, $//;

    # end local variables

    # only status messages printed from now on
    print STDOUT ("<div id='statusblock'>\n");

    my $uid = $html->param('username');

    print STDOUT (
            $html->p(
                     {'-class' => 'errortext'},
                     "Missing username. Click back in your browser to fix it.\n"
                    )
                 )
      and goto EXIT
      if ($uid eq "" or $uid !~ /^[^[:blank:]]+$/);

    if ($html->param('delete_user') and $html->param("delete_user") eq "on")
    {

        # we are deleting this account
        # Note that we do not delete POSIX users here

        # we need to know if the user exist in the db and this is not
        # a POSIX account, then we can delete it, else we print a warning
        # and we do not delete this

        _debug($LDAPADMINCN);
        _debug(_get_password($LDAPPASSWORDFILE));

        my $mesg =
          $ldap->bind(
                      $LDAPADMINCN,
                      'password' => _get_password($LDAPPASSWORDFILE),
                      'version'  => '3'
                     );    # if bind() it binds anonymously

        # first get the actual dn
        my $result_search =
          _ldap_search($ldap, "uid=$uid", ['uid', 'objectClass']);

        # we should only find 1 entry
        if ($result_search->count() != 1)
        {
            print($html->p(
                           {'-class' => 'errortext'},
                           " Error while deleting uid $uid on $LDAPSERVER: "
                             . $result_search->error_text()
                             . ". User $uid was not found in the database\n"
                          )
                 );
            goto EXIT;
        }
        my @entries = $result_search->entries;

        # if this is a posixAccount, print error and go to EXIT
        my @attributes = $entries[0]->get_value('objectClass');
        foreach my $_attrs (@attributes)
        {
            if ($_attrs eq 'posixAccount')
            {
                print STDOUT (
                    $html->p(
                             {'-class' => 'errortext'},
                             " Cannot delete user $uid on $LDAPSERVER. This is a POSIX account "
                            )
                );
                goto EXIT;
            }
        }

        my $_dn = $entries[0]->dn();    # yes.. get the DN
                                        #if ($entries[0]->exists('uid'))

        my $entry_result = $ldap->delete($_dn);
        if ($entry_result->code())
        {
            print($html->p(
                           {'-class' => 'errortext'},
                           " Error while deleting user $uid on $LDAPSERVER: "
                             . $entry_result->error_text()
                          )
                 );

            _debug(  ". Server message => code: "
                   . $entry_result->code()
                   . ". name: "
                   . $entry_result->error_name()
                   . ". text: "
                   . $entry_result->error_text());
            goto EXIT;
        }
        print $html->p({'-class' => "successtext"},
                       "User $uid deleted successfully");
    }
    else
    {

        # we are creating a user
        my $first     = $html->param('firstname');
        my $last      = $html->param('lastname');
        my $uid       = $html->param('username');
        my $password  = $html->param('password');
        my $email     = $html->param('email');
        my $telephone = $html->param('telephone');

        my $RANDOM_PASSWORD_USED = 0;

        print STDOUT (
            $html->p(
                     {'-class' => 'errortext'},
                     "Missing first name and/or last name. Click back in your browser to fix it.\n"
                    )
          )
          and goto EXIT
          if (   $first eq ""
              or $last eq ""
              or $first !~ /^[^[:blank:]]+$/
              or $last !~ /^[^[:blank:]]+$/);

        print STDOUT (
               $html->p(
                        {'-class' => 'errortext'},
                        "Missing email. Click back in your browser to fix it.\n"
                       )
                     )
          and goto EXIT
          if ($email eq "" or $email !~ /^[^[:blank:]]+\@[^[:blank:]]+$/);

        print STDOUT (
               $html->p(
                     {'-class' => 'errortext'},
                     "Missing username. Click back in your browser to fix it.\n"
               )
          )
          and goto EXIT
          if ($uid eq "" or $uid !~ /^[^[:blank:]]+$/);

        # create UID and MID using scheme:
        #   (first letter of first name) + (last name)
        $uid = ($uid) ? $uid : lc(substr($first, 0, 1) . $last);
        my $mid = lc($first) . '.' . lc($last);

        my $full_name = ucfirst($first) . " " . ucfirst($last);

        #my $initials  = substr($first, 0, 1) . substr($last, 0, 1);

        my $ou = ($OU) ? "ou=$OU, " : "ou=People, ";
        if (!$password)
        {
            $RANDOM_PASSWORD_USED = 1;
            $password             = random_password(8);
        }

        my $hash_password = hash_password($password);

        _debug($LDAPADMINCN);

        #_debug(_get_password($LDAPPASSWORDFILE));

        my $mesg =
          $ldap->bind(
                      $LDAPADMINCN,
                      'password' => _get_password($LDAPPASSWORDFILE),
                      'version'  => '3'
                     );    # if bind() it binds anonymously

        my $result_search =
          _ldap_search($ldap, "uid=$uid", ['uid', 'email', 'cn']);

        if (    $html->param("password_reset")
            and $html->param("password_reset") eq "on")
        {

            # we are reseting a password here, does the user exists and
            # only 1 user has this uid?
            if ($result_search->count() == 1)
            {
                my @entries = $result_search->entries;
                my $_dn     = $entries[0]->dn();         # yes.. get the DN

                # now do the fields that we will modify
                my %_modify_hash =
                  ('userPassword' => "${PASS_SCHEME}${hash_password}");

                my $entry_result = _modify_entry($ldap, $_dn, \%_modify_hash);
                if ($entry_result->code())
                {
                    print($html->p(
                            {'-class' => 'errortext'},
                            " Error while reseting password for uid $uid on $LDAPSERVER: "
                              . $entry_result->error_text()
                        )
                    );

                    _debug(  ". Server message => code: "
                           . $entry_result->code()
                           . ". name: "
                           . $entry_result->error_name()
                           . ". text: "
                           . $entry_result->error_text());
                    goto EXIT;
                }
                print $html->p({'-class' => "successtext"},
                               "Password reset successfully for user $uid (email: $mid\@$domain)"
                              );

                # email user
                goto SUCCESS;
            }
            else
            {
                print($html->p(
                             {'-class' => 'errortext'},
                             " Error no user with uid $uid found on $LDAPSERVER. Try creating it first. "
                    )
                );

                # bail out
                goto EXIT;
            }
        }
        else
        {

            # we are creating new users, does the user already exists?
            if ($result_search->count() == 1)
            {

                # bail out
                print $html->p({'-class' => 'errortext'},
                               "An user with uid $uid already exits");
                if ($DEBUG)
                {
                    print $html->start_table();

                    my $max = $mesg->count();
                    for (my $i = 0 ; $i < $max ; $i++)
                    {
                        my $entry = $mesg->entry($i);
                        foreach my $attr ($entry->attributes())
                        {
                            next
                              if ($attr =~ /passw/);    # skip password printing
                            print STDOUT (
                                          $html->Tr(
                                              $html->td($attr),
                                              $html->td(
                                                  $html->span(
                                                      {'-class' => 'errortext'},
                                                      $entry->get_value($attr)
                                                  )
                                              )
                                          ),
                                          "\n"
                                         );
                        }
                    }
                    print $html->end_table();
                }

                goto EXIT;
            }
            elsif ($result_search->count() > 1)
            {
                print STDOUT (
                    $html->p(
                        {'-class' => 'errortext'},
                        " Error while creating entry for uid $uid on $LDAPSERVER: "
                          . "More than one user with that uid"
                    )
                );

                goto EXIT;
            }
            else
            {

                # at this point we can create the account
                my $ldif = "
dn: uid=${uid},${ou}${domain_joined}
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetorgperson
cn: $full_name
sn: $last
givenName: $first
uid: $uid
mail: $mid\@$domain
telephoneNumber: $telephone
userPassword: ${PASS_SCHEME}${hash_password}
\n";

                print STDOUT ("<!-- \n", $ldif, "\n -->\n");
                my $_dn = "uid=${uid},${ou}${domain_joined}";
                my $create_ary = [
                    objectClass => [
                        "top", "person", "organizationalPerson", "inetorgperson"
                                   ],
                    cn              => $full_name,
                    uid             => $uid,
                    givenName       => $first,
                    sn              => $last,
                    mail            => "${mid}\@${domain}",
                    telephoneNumber => $telephone,
                    userPassword    => "${PASS_SCHEME}${hash_password}"
                ];

                my $entry_result = _create_entry($ldap, $_dn, $create_ary);
                if ($entry_result->code())
                {
                    print($html->p(
                            {'-class' => 'errortext'},
                            " Error while creating entry for uid $uid on $LDAPSERVER: "
                              . $entry_result->error_text()
                        )
                    );

                    _debug(  ". Server message => code: "
                           . $entry_result->code()
                           . ". name: "
                           . $entry_result->error_name()
                           . ". text: "
                           . $entry_result->error_text());
                    goto EXIT;
                }

                print $html->p({'-class' => "successtext"},
                               "User $uid created (email: $mid\@$domain)");
            }
        }

      SUCCESS:

        # some last minute messages
        print $html->p(
                       {'-class' => "successtext"},
                       "Random password used is $password. This was emailed to the end-user $mid\@$domain"
                      ) if ($RANDOM_PASSWORD_USED);

        my $_message = $TEMPLATE_MESSAGE;

        $_message =~ s/\@fullname\@/$full_name/mi;
        $_message =~ s/\@username\@/$uid/mi;
        $_message =~ s/\@firstname\@/$first/mi;
        $_message =~ s/\@lastname\@/$last/mi;
        $_message =~ s/\@email\@/"${mid}\@${domain}"/mi;
        $_message =~ s/\@password\@/$password/mi;

        # send email:
        my %message = (
                       'mailhost' => $MAILHOST,
                       'subject'  => $SUBJECT,
                       'to'       => "${mid}\@${domain}",
                       'cc'       => $CC,
                       'from'     => $FROM,
                       'message'  => $_message
                      );

        _send_email(\%message);
    }

    print "</div>\n";

  EXIT:
    $ldap->unbind();    # take down session
    $ldap->disconnect();
}

print($html->end_html(), "\n");

