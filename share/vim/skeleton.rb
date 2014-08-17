#!/usr/bin/env ruby

=begin
$Revision: 1.0.1 $
$Date: 2011-08-16 21:31 EDT $
my_name < email@example.com >

DESCRIPTION:
USAGE: skeleton --help
LICENSE: ___
=end

require 'optparse'
require 'ostruct'

# The options specified on the command line will be collected in *options*.
# We set default values here.
options = OpenStruct.new
# options.library = []
# options.inplace = false
# options.encoding = "utf8"
# options.transfer_type = :auto
options.verbose = 0 # levels 0 - 10

opts = OptionParser.new do |opts|
   opts.banner = "Usage: skeleton [options]"

   opts.separator ""
   opts.separator "Specific options:"

   # Mandatory argument.
#    opts.on("-r", "--require LIBRARY",
#    "Require the LIBRARY before executing your script") do |lib|
#       options.library << lib
#    end

   # Optional argument; multi-line description.
   #opts.on("-i", "--inplace [EXTENSION]",

#    # Cast 'time' argument to a Time object.
#    opts.on("-t", "--time [TIME]", Time, "Begin execution at given time") do |time|
#       options.time = time
#    end

#    # List of arguments.
#    opts.on("--list x,y,z", Array, "Example 'list' of arguments") do |list|
#       options.list = list
#    end

#    # Optional argument with keyword completion.
#    opts.on("--type [TYPE]", [:text, :binary, :auto],
#    "Select transfer type (text, binary, auto)") do |t|
#       options.transfer_type = t
#    end

   # Boolean switch.
   opts.on("-v", "--[no-]verbose", "Run verbosely. Increase level of verbosity by using multiple -v") do |v|
      options.verbose += 1
   end
   opts.on("-D", "--[no-]debug", "Show debug messages") do |v|
      options.debug = v
      options.verbose += 10
   end

   opts.separator ""
   opts.separator "Common options:"

   # No argument, shows at tail.  This will print an options summary.
   # Try it and see!
   opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
   end

   # Another typical switch to print the version.
   opts.on_tail("--version", "Show version") do
      puts "v1.0" # revision
      exit
   end
end

begin
   opts.parse!(ARGV)
rescue OptionParser::MissingArgument => e
   $stderr.puts e.message
rescue => e
   $stderr.puts "Unknown error: #{e.message}"
end

$_verbose   = options.verbose
$_debug     = options.debug

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
   if STDOUT.tty?
     ansicolor = "#{colors[color.downcase]}#{msg}#{colors['norm']}"
   else
     msg
   end
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
def verbose(msg,level=1)
   return if $_verbose <= 0
   puts "#{msg}" if $_verbose >= level
end
def error(msg)
   $stderr.puts scolor("ERROR: #{msg}","red")
end
# end helpers

# main()

begin
   str = "Hello"
   val = "World"

   # demonstrates debug:
   debug(str,val)

   # demonstrates verbose:
   verbose("printing verbose message level 1")
   verbose("printing verbose message level 2",2)

   puts "sample"

   # demonstrates raising/throwing errors
   raise MyError, "Too many repetitions" if options.list and options.list.size > 10
rescue MyError => e
   error e.message
end
