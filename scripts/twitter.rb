#!/usr/bin/env ruby
# == Synopsis
#
# Twitter: a simple Ruby client for Twitter.com
#
# == Usage
#
# twitter [OPTION]
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
# -m, --message <message>:
#     Message to post
#
# -p, --password <password>:
#     Twitter password for username
#
# -q, --quiet
#     Do not display messages
#
# -t, --uid <userid>:
#     Twitter user ID number. Use this to get status from other twitter user
#     i.e. ./twitter.rb -t 17058142
#
# -u, --username <username>:
#     Twitter user


=begin
$Revision: 0.2 $
$Date: 2009-11-12 12:51 EST $
Luis Mondesi <lemsx1@gmail.com>

DESCRIPTION:
USAGE: twitter.rb --help
LICENSE: GPL
=end


# defaults:
twitterid   = nil
username    = nil
password    = nil
message     = nil
quiet       = false

#TODO read start file ~/.twitterrc

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
[ '--repeat', '-n', GetoptLong::REQUIRED_ARGUMENT ],
[ '--username', '-u', GetoptLong::REQUIRED_ARGUMENT ],
[ '--password', '-p', GetoptLong::REQUIRED_ARGUMENT ],
[ '--message', '-m', GetoptLong::REQUIRED_ARGUMENT ],
[ '--quiet', '-q', GetoptLong::NO_ARGUMENT ],
[ '--uid', '-t', GetoptLong::REQUIRED_ARGUMENT ]
)

opts.each do |opt, arg|
   case opt
   when '--help'
      RDoc::usage
   when '--usage'
      RDoc::usage
   when '--username'
      if arg == ''
         # this is redundant...
         raise "username missing. See --usage"
      else
         username = arg
      end
   when '--password'
      if arg == ''
         raise "password missing. See --usage"
      else
         password = arg
      end
   when '--message'
      if arg =~ /^\s+$/
         raise "message cannot be blank. See --usage"
      else
         message = arg
      end
   when '--quiet'
      quiet = true
   when '--uid'
      twitterid = arg
   end
end

# helpers
def twitter(user, password, command, opts={}, type=:get)
   # Open an HTTP connection to twitter.com
   twitter = Net::HTTP.start('twitter.com')

   # Depending on the request type, create either
   # an HTTP::Get or HTTP::Post object
   case type
   when :get
      # Append the options to the URL
      command << "?" + opts.map{|k,v| "#{k}=#{v}" }.join('&')
      req = Net::HTTP::Get.new(command)

   when :post
      raise "user missing" if not user
      raise "password missing" if not password
      # Set the form data with options
      req = Net::HTTP::Post.new(command)
      req.set_form_data(opts)
   end

   # Set up the authentication and
   # make the request
   req.basic_auth( user, password ) if user and password
   res = twitter.request(req)

   # Raise an exception unless Twitter
   # returned an OK result
   unless res.is_a? Net::HTTPOK
      doc = Hpricot(res.body)
      raise "#{(doc/'request').inner_html}: #{(doc/'error').inner_html}"
   end

   # Return the request body
   return res.body
end

# main()
cmd = {
   :user    => "/statuses/user_timeline/#{twitterid}.xml",
   :friends => "/statuses/friends_timeline.xml",
   :update  => "/statuses/update.xml",
}
opts = {
   'lat' => 40,
   'long' => 73
}
doc = nil

# Make an API query and parse the output
if message
   if message.length > 139
      opts['status'] = message[0..136] + '.' * 3
   else
      opts['status'] = message
   end
   doc = Hpricot(twitter(username,password,cmd[:update],opts,:post))
else
   # TODO how do I get the ID of this user? so we can do /statuses/show/id.xml
   # or at least get the UID of user username

   raise "Twitter ID missing" if not twitterid
   doc = Hpricot(twitter(username,password,cmd[:user],opts))
end

# If zero statuses were returned, then
# there are no new updates
if not quiet and (doc/'status').length > 0
   # Get the time of the first update
   #last_id = (doc/'status id').first.inner_html

   # Print in reverse order so newest are
   # printed at the bottom of the list
   st = (doc/'status').first
   #user = (st/'user name').inner_html
   text = (st/'text').inner_html
   # prints text not directed at somebody else
   if text !~ /^[[:blank:]]*@/ or text !~ /^[[:blank:]]*d[[:blank:]]+/
      puts "<span class='status-body'>
      <span class='entry-content'>"
      puts "<a href='http://twitter.com/#{username}'>#{text}</a>"
      puts "              </span>
      </span>"
   end
end
