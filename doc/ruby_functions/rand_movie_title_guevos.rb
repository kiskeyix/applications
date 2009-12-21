#!/usr/bin/env ruby
# == Synopsis
#
# Randon Movie Title from imdb's top 250 
# and adds the string "guevos" to the title
#
# == Usage
#
# rand_movie_title_guevos [OPTION]
#
# -h, --help:
#    show help
#
# --count x, -n x:
#    show N movies
#
# --usage, -U, -?:
#    show usage

=begin
$Revision: 0.1 $
$Date: 2009-12-21 00:24 EST $
Luis Mondesi <lemsx1@gmail.com>

DESCRIPTION:
USAGE: rand_movie_title_guevos.rb --help
LICENSE: GPL
=end


# defaults:
count = 1

#### --------------- do not modify below this line --------------- ####

# libs we need:
require 'rubygems'
require 'hpricot'
require 'net/http'
require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
[ '--usage', '-U', '-?', GetoptLong::NO_ARGUMENT ],
[ '--count', '-n', GetoptLong::REQUIRED_ARGUMENT ]
)

opts.each do |opt, arg|
   case opt
   when '--help'
      RDoc::usage
   when '--usage'
      RDoc::usage
   when '--count'
      if arg == ''
         raise "number missing. See --usage"
      else
         count = arg.to_i
      end
   end
end

# helpers
def imdb(command, opts={}, type=:get)
   # Open an HTTP connection to imdb
   site = Net::HTTP.start('www.imdb.com')

   # Depending on the request type, create either
   # an HTTP::Get or HTTP::Post object
   case type
   when :get
      # Append the options to the URL
      #command << "?" + opts.map{|k,v| "#{k}=#{v}" }.join('&')
      req = Net::HTTP::Get.new(command)
   end

   res = site.request(req)
   
   # Raise an exception unless IMDB
   # returned an OK result
   unless res.is_a? Net::HTTPOK
      raise res.error!

      #doc = Hpricot(res.body)
      #raise "#{(doc/'request').inner_html}: #{(doc/'error').inner_html}"
   end

   # Return the request body
   return res.body
end

# main()
cmd = {
   :top    => "/chart/top",
}
opts = { }
doc = nil

# Make GET query and parse the output
doc = Hpricot(imdb(cmd[:top],opts))

#<div id="main">
#<a href="/title/tt0111161/">The Shawshank Redemption</a>

movies = doc/'//div[@id="main"]'/'a'

count.times {
   movie = movies[rand movies.length]
   words = movie.inner_html.split(/\s+/)
   redo if (words.length == 1) # it's boring to have 1 word...
   words[words.size - 1] = "guevos"
   puts words.join(" ") + " [#{movie.inner_html}]"
}
