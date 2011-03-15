#!/usr/bin/env ruby
# == Synopsis
#
# fgrep.rb: finds a string in a set of files
#
# == Usage
#
# fgrep.rb [OPTION] <REGEX>
#
# --debug, -D:
#    show colorful debugging information
#
# --help, -h:
#    show help
#
# --replace, -r <STRING>:
#    use STRING as replacement
#
# --usage, -U, -?:
#    show usage
#
# --verbose, -v
#    shows verbose messages

=begin
$Revision: 1.0 $
$Date: 2011-03-09 01:40 EST $
Luis Mondesi <lemsx1@gmail.com>

DESCRIPTION:
USAGE: fgrep.rb --help
LICENSE: GPL
=end


require 'getoptlong'

opts = GetoptLong.new(
[ '--debug',   '-D', GetoptLong::NO_ARGUMENT ],
[ '--help',    '-h', GetoptLong::NO_ARGUMENT ],
[ '--usage',   '-U', '-?', GetoptLong::NO_ARGUMENT ],
[ '--verbose', '-v', GetoptLong::NO_ARGUMENT ],
[ '--replace', '-r', GetoptLong::REQUIRED_ARGUMENT ]
)

$_verbose   = false
$_debug     = false
replacement = nil

def usage
   puts "fgrep.rb [OPTION] <REGEX>"
   puts <<EOF
  --debug, -D:
     show colorful debugging information

  --help, -h:
     show help

  --replace, -r <STRING>:
     use STRING as replacement

  --usage, -U, -?:
     show usage

  --verbose, -v
     shows verbose messages
EOF
   exit 0
end

opts.each do |opt, arg|
   case opt
   when '--help'
      usage
   when '--usage'
      usage
   when '--verbose'
      $_verbose=true
   when '--debug'
      $_debug=true
   when '--replace'
      replacement=arg
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
def report(location,line,color='blue')
   puts "#{scolor(location,color)}:#{line}"
end
# end helpers

# main()
regex    = ARGV.shift or ".*"
fpattern = ARGV.shift

begin
   require 'find'
   Find.find(".") do |file|
      next if not File.file? file
      if fpattern and file !~ /#{fpattern}/
         next
      end
      debug file
      line_num = 0
      tmp_file = nil
      rfile    = nil
      modified = false
      if replacement
         tmp_file = file + ".#{$$}"
         rfile = open(tmp_file,"w")
      end
      open(file,"r").each do |line|
         line_num += 1
         if replacement
            if line.gsub!(/#{regex}/,replacement)
               modified = true
               report "#{file}[#{line_num}]", line, 'red'
            end
            rfile.puts line
         else
            report "#{file}[#{line_num}]", line, 'blue' if line =~ /#{regex}/
         end
      end
      rfile.close if rfile
      if tmp_file and File.file? tmp_file
         if modified
            File.rename tmp_file, file
         else
            File.unlink tmp_file
         end
      end
   end
rescue MyError => e
   error e.message
rescue Interrupt
end
