#!/usr/bin/env ruby
# == Synopsis
#
# make_home_dir: use this script to make missing home directories for users
# Note that this will only make directories when user ids are greater than
# 1000
#
# == Usage
#
# make_home_dir [OPTION]
#
# make_home_dir [--ldap|--passwd]
#
# defaults to --passwd (getent passwd)
#
# -h, --help:
#    show help
#
# --usage, -U, -?:
#    show usage
#
# --ldap
#    use ldap to get user information
#
# --passwd
#    use passwd db to get user information (default)

=begin
$Revision: 1.0 $
$Date: 2008-12-19 01:00 EST $
Luis Mondesi <lemsx1@gmail.com> 

DESCRIPTION:
USAGE: make_home_dir --help
LICENSE: ___
=end

require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
[ '--usage', '-U', '-?', GetoptLong::NO_ARGUMENT ],
[ '--passwd', GetoptLong::NO_ARGUMENT ],
[ '--ldap', GetoptLong::NO_ARGUMENT ]
)

passwd=1
ldap=0
opts.each do |opt, arg|
   case opt
   when '--help'
      RDoc::usage
   when '--usage'
      RDoc::usage
   when '--passwd'
      passwd=1
      ldap=0
   when '--ldap'
      ldap=1
      passwd=0
   end
end

# start script
if (Process.euid != 0)
   puts "You must run this as root"
   exit 1
end

require 'fileutils.rb'

# utilities
def die (msg="error")
   rescue raise(msg)
end

def copy_skel (dir,skel='/etc/skel/')
   if (not File.directory?(dir))
      FileUtils.cp_r(skel,dir)
      FileUtils.chmod(0700,dir)
      return true
   end
   return false
end

# using ldap directly:
def using_ldap
   users = `ldapsearch -x 'loginshell=/bin/bash'|grep -v umber| grep -vi People|grep uid|cut -c 6-`
   die ("failed to execute ldapsearch #{$!}") if ($? != 0)
   users.each do |user|
      dir = '/home/' + user.chomp
      if (copy_skel(dir))
         FileUtils.chown(user.chomp,'users',dir)
      end
   end
end

def using_passwd
   # using passwd db
   passwd = `getent passwd`
   die ("failed to execute 'getent passwd' #{$!}") if ($? != 0)
   passwd.each do |line|
      entry = line.chomp.split(/:/)
      next if entry[2].to_i < 1000
      if (copy_skel(entry[5]))
         FileUtils.chown(entry[0],entry[3].to_i,entry[5])
      end
   end
end

if (passwd)
   using_passwd()
elsif (ldap)
   using_ldap()
else
   # never reaches this
   RDoc::usage 1
end
