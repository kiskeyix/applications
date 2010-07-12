#!/usr/bin/env ruby
# == Synopsis
#
# triangle: finds max sum of top-to-bottom triangle
#
# i.e.:
# Given a triangle like this
#
# 5
# 9 6
# 4 6 8
# 0 7 1 5
#
# It displays the path with the highest sum
# 5 + 9 + 6 + 7 = 27
#
# A more interesting input is here: http://www.yodle.com/puzzles/triangle.txt
#
# == Usage
#
# triangle <FILE>
#
# --debug, -D:
#    show colorful debugging information
#
# --help, -h:
#    show help
#
# --usage, -U, -?:
#    show usage
#
# --verbose, -v
#    shows verbose messages
#
# FILE: The triangle is defined in this file
#
# == Known Bugs
# 
# There is no sanity checks on input

=begin
$Revision: 0.1 $
$Date: 2010-07-12 17:04 EDT $
Luis Mondesi <lemsx1@gmail.com>

DESCRIPTION:
USAGE: triangle --help
LICENSE: GPL
=end


require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
[ '--debug',   '-D', GetoptLong::NO_ARGUMENT ],
[ '--help',    '-h', GetoptLong::NO_ARGUMENT ],
[ '--usage',   '-U', '-?', GetoptLong::NO_ARGUMENT ],
[ '--verbose', '-v', GetoptLong::NO_ARGUMENT ]
)

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
   end
end

# helpers
class MyError < StandardError
end
# end helpers

# main()

class Tree
   def initialize(file)
      @db = Array.new
      @sums = Hash.new

      i = 0
      open(file,"r").each_line do |line|
         @db[i] = line.chomp.split(/\s+/)
         i = i+1
      end

      sumtree(0,0,"",0)
   end
   
   def sumtree(x,y,key,val)
      if x < @db.size
         ckey = key + @db[x][y].to_s + ","
         cval = val + @db[x][y].to_i
         #left
         sumtree(x+1,y,ckey,cval)
         #right
         sumtree(x+1,y+1,ckey,cval)
      else
         @sums[key]=val
      end
   end

   def max_path
      mkey = String.new
      f = false
      @sums.each do |key,val|
         if f
            if val > @sums[mkey]
               mkey = key
            end
         else
            mkey = key
            f = true
         end
      end
      [mkey,@sums[mkey]]
   end

   def print_sums
      p @sums
   end
end

begin
   triangle = Tree.new(ARGV[0])
   #triangle.print_sums
   p triangle.max_path
rescue MyError => e
   error e.message
end
