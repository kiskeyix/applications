#!/usr/bin/env ruby
# == Synopsis
#
# port-uninstall: recursively removes ports and its dependencies
#
# == Usage
#
# port-uninstall [OPTION] ... <port>
#
# -h, --help:
#    show help
#
# --usage, -U, -?:
#    show usage
#
# port: The port package to remove

=begin
$Revision: 1.0 $
$Date: 2009-01-01 23:54 EST $
Luis Mondesi <lemsx1@gmail.com> 

DESCRIPTION: recursively removes ports and its dependencies
USAGE: port-uninstall --help
LICENSE: GPL
=end


require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
[ '--usage', '-U', '-?', GetoptLong::NO_ARGUMENT ]
)

port = nil
opts.each do |opt, arg|
   case opt
   when '--help'
      RDoc::usage
   when '--usage'
      RDoc::usage
   end
end

if ARGV.length != 1
   puts "Missing port argument (try --help)"
   RDoc::usage 1
   exit 1 # never reaches here
end

# helpers
def get_pkg_name(str)
   return str[4,str.length].strip
end

# recursively remove dependencies
def remove_port(port)
   loop {
      break if (port =~ /\s/ )
      if (port =~ /Deactivating/)
         puts port
         exit 1
      end
      if (port =~ /Uninstalling/)
         puts port
         exit 1
      end
      
      puts "removing port #{port}"
      ports = `sudo port uninstall #{port} 2>&1`

      if ports =~ /Error:.*Please\s+uninstall\s+the\s+ports\s+that\s+depend/
         ports.each { |line|
            next if line !~ /--->\s+/ or line =~ /Unable\s+to/ \
               or line =~ /Deactivating/
               remove_port(get_pkg_name(line))
         }
      else
         break
      end
   }
end

remove_port(ARGV.shift)
