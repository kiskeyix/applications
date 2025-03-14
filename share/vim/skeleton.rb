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

VERSION="0.0.1"

# The options specified on the command line will be collected in *options*.
# We set default values here.
options = OpenStruct.new
# options.library = []
options.verbose = 0 # levels 0 - 10
options.debug = false

opts = OptionParser.new do |o|
  o.banner = "Usage: #{File.basename $0} [options]"

  o.separator ""
  o.separator "Specific options:"

  # Mandatory argument.
  #    o.on("-r", "--require LIBRARY",
  #    "Require the LIBRARY before executing your script") do |lib|
  #       options.library << lib
  #    end

  # Optional argument; multi-line description.
  #o.on("-i", "--inplace [EXTENSION]",

  #    # Cast 'time' argument to a Time object.
  #    o.on("-t", "--time [TIME]", Time, "Begin execution at given time") do |time|
  #       options.time = time
  #    end

  #    # List of arguments.
  #    o.on("--list x,y,z", Array, "Example 'list' of arguments") do |list|
  #       options.list = list
  #    end

  #    # Optional argument with keyword completion.
  #    o.on("--type [TYPE]", [:text, :binary, :auto],
  #    "Select transfer type (text, binary, auto)") do |t|
  #       options.transfer_type = t
  #    end

  # Boolean switch.
  o.on("-v", "--[no-]verbose", "Run verbosely. Increase level of verbosity by using multiple -v") do |v|
    options.verbose += 1
  end
  o.on("-D", "--[no-]debug", "Show debug messages") do |v|
    options.debug = v
    options.verbose += 10
  end

  o.separator ""
  o.separator "Common options:"

  # No argument, shows at tail.  This will print an options summary.
  # Try it and see!
  o.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  # Another typical switch to print the version.
  o.on_tail("--version", "Show version") do
    puts VERSION
    exit
  end
end

begin
  opts.parse!(ARGV)
rescue OptionParser::MissingArgument => e
  $stderr.puts e.message
  puts opts
  exit 1
rescue => e
  $stderr.puts "ERROR: #{e.class} #{e.message}"
  exit 2
end

# helpers
class MyError < StandardError; end

class MyExample
  def initialize(opts={})
    @debug = opts[:debug]
    @verbose = opts[:verbose] || 0
  end

  def scolor(msg,color)
    colors = {
      'red'    => "\033[1;31m",
      'norm'   => "\033[0;39m",
      'green'  => "\033[0;32m",
      'blue'   => "\033[0;34m"
    }
    if STDOUT.tty?
      "#{colors[color.downcase]}#{msg}#{colors['norm']}"
    else
      msg
    end
  end
  def debug(*msg)
    return if not @debug

    $stderr.print scolor('DEBUG: ', 'green')
    if msg[1].to_s > ''
      # val.to_s is called for us:
      $stderr.puts "#{scolor(msg[0], 'blue')} = #{scolor(msg[1..-1].join(' '), 'red')}"
    else
      $stderr.puts "#{scolor(msg.join(' '), 'blue')}"
    end
  end
  def info(*msg)
    prefix = 'INFO: ' unless msg[0] =~ /^\s*INFO:/
    $stderr.puts scolor("#{prefix}#{msg.join(' ')}", "blue")
  end
  alias warn info
  def verbose(msg,level=1)
    return if @verbose <= 0
    puts "#{msg}" if @verbose >= level
  end
  def error(*msg)
    prefix = 'ERROR: ' unless msg[0] =~ /^\s*ERROR:/
    $stderr.puts scolor("#{prefix}#{msg.join(' ')}", "red")
  end
end
# end helpers

# main()

begin
  str = "Hello"
  val = "World"

  obj = MyExample.new debug: options.debug, verbose: options.verbose

  # demonstrates debug:
  obj.debug(str, val, 'extra')
  obj.error('this', 'is', 'error', 'with', 'extra')
  obj.info('this', 'is', 'info', 'with', 'extra')
  obj.info('this is also info with', 'extra')

  # demonstrates verbose:
  obj.verbose("printing verbose message level 1")
  obj.verbose("printing verbose message level 2", 2)

  puts "sample" unless $_testing

  # demonstrates raising/throwing errors
  raise MyError, "Too many repetitions" if options.list and options.list.size > 10
rescue MyError => e
  error e.message
end
