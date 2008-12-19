#!/usr/bin/env ruby
# == Synopsis
#
# skeleton: foo bar
#
# == Usage
#
# skeleton [OPTION] ... <DIR>
#
# -h, --help:
#    show help
#
# --repeat x, -n x:
#    repeat x times
#
# --usage, -U, -?:
#    show usage
#
# --name [name]:
#    greet user by name, if name not supplied default is John
#
# DIR: The directory in which to issue the greeting.

=begin
$Revision: 1.0 $
$Date: 2007-03-01 21:41:46 $
my_name < email@example.com >

DESCRIPTION:
USAGE: skeleton --help
LICENSE: ___
=end


require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
[ '--usage', '-U', '-?', GetoptLong::NO_ARGUMENT ],
[ '--repeat', '-n', GetoptLong::REQUIRED_ARGUMENT ],
[ '--name', GetoptLong::OPTIONAL_ARGUMENT ]
)

dir = nil
name = nil
repetitions = 1
opts.each do |opt, arg|
   case opt
   when '--help'
      RDoc::usage
   when '--usage'
      RDoc::usage
   when '--repeat'
      if arg.chomp.empty? || arg.to_i < 1
         puts 'Repeat number is wrong (try --help)'
         RDoc::usage 1
      else
         #puts "arg is:'" + arg + "'"
         repetitions = arg.to_i
      end
   when '--name'
      if arg == ''
         name = 'John'
      else
         name = arg
      end
   end
end

if ARGV.length != 1
   puts "Missing dir argument (try --help)"
   RDoc::usage 1
   exit 1 # never reaches here
end

dir = ARGV.shift

Dir.chdir(dir)
for i in (1..repetitions)
   print "Hello"
   if name
      print ", #{name}"
   end
   puts
end
