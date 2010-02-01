#!/usr/bin/ruby
# == Synopsis
#
# skeleton: foo bar
#
# == Usage
#
# skeleton [OPTION] ... <DIR>
#
# --debug, -D:
#    show colorful debugging information
#
# --help, -h:
#    show help
#
# --name, -n [name]:
#    greet user by name, if name not supplied default is John
#
# --repeat, -r x:
#    repeat x times
#
# --usage, -U, -?:
#    show usage
#
# --verbose, -v
#    shows verbose messages
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
[ '--debug',   '-D', GetoptLong::NO_ARGUMENT ],
[ '--help',    '-h', GetoptLong::NO_ARGUMENT ],
[ '--name',    '-n', GetoptLong::OPTIONAL_ARGUMENT ],
[ '--repeat',  '-r', GetoptLong::REQUIRED_ARGUMENT ],
[ '--usage',   '-U', '-?', GetoptLong::NO_ARGUMENT ],
[ '--verbose', '-v', GetoptLong::NO_ARGUMENT ]
)

dir         = nil
name        = nil
repetitions = 1
$_verbose   = false
$_debug     = false

opts.each do |opt, arg|
   case opt
   when '--help'
      RDoc::usage
   when '--usage'
      RDoc::usage
   when '--verbose'
      $_verbose=true
   when '--debug'
      $_debug=true
   when '--repeat'
      if arg.chomp.empty? || arg.to_i < 1
         puts 'Repeat number is wrong (try --help)'
         RDoc::usage 1
      else
         #puts "arg is:'" + arg + "'"
         repetitions = arg.to_i
      end
   when '--name'
      if not arg
         name = 'John'
      else
         name = arg
      end
   end
end

# helpers
class MyError < StandardError
end
def scolor(msg,color)
   colors = {
      'red'    => "\033[1;31m",
      'norm'   => "\033[0;39m",
      'green'  => "\033[0;32m",
      'blue'   => "\033[0;34m"
   }
   ansicolor = "#{colors[color.downcase]}#{msg}#{colors['norm']}"
end
def debug(msg,val="")
   return if not $_debug
  
   $stderr.print scolor("DEBUG: ",'green')
   if val
      # val.to_s is called for us:
      $stderr.puts "#{scolor(msg,'blue')} = #{scolor(val,'red')}"
   else
      $stderr.puts "#{scolor(msg,'blue')}"
   end
end
def verbose(msg)
   return if not $_verbose
   puts "#{msg}"
end
def error(msg)
   $stderr.puts scolor("ERROR: #{msg}","red")
end
# end helpers

# main()

# if ARGV.length != 1
#    puts "Missing dir argument (try --help)"
#    RDoc::usage 1
#    exit 1 # never reaches here
# end
#
# dir = ARGV.shift
#
# Dir.chdir(dir)
# for i in (1..repetitions)
#    print "Hello"
#    if name
#       print ", #{name}"
#    end
#    puts
# end

begin
   str = "Hello"
   val = "World"

   # demonstrates debug:
   debug(str,val)
   debug("name",name)
   debug("repetitions",repetitions)

   # demonstrates verbose:
   verbose("printing all variables: ")

   print "#{name}, " if name

   raise MyError, "Too many repetitions" if repetitions > 10

   1.upto(repetitions) do
      puts str + " " + val
   end
rescue MyError => e
   error e.message
end
