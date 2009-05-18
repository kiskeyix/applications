#!/usr/bin/env ruby
#
# There is no default way in ruby to do:
# foo[:bar][:baz] = "more foo"
#

#  http://blog.inquirylabs.com/2006/09/20/ruby-hashes-of-arbitrary-depth/
hash = Hash.new(&(p=lambda{|h,k| h[k] = Hash.new(&p)}))
hash['one']['two']="two"

puts hash

# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/13408 
class HashMD < Hash
   def [](n)
      self[n]=HashMD.new if super(n)==nil
      super(n)
   end
end
h = HashMD.new
h['a']['b']['c'] = 'xxx'  #=>  {"a" => {"b" => {"c" => "xxx"}}}
puts h
