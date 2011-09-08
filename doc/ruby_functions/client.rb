#!/usr/bin/env ruby
# Use this client to test latency. See server.rb
# On a loopback interface this happens in 0.0002012 seconds
# (0.2ms)
#
# Luis Mondesi <lemsx1@gmail.com>
# 2011-09-08 14:36 EDT

require 'socket'
begin
   puts "client"
   loop do
      begin 
         t = Time.now
         if c = TCPSocket.new(ARGV[0], 8000)
            print "#{t.to_f} "
            puts "#{c.gets.to_f - t.to_f}"
         else
            puts "failed #{t.to_f}"
         end
      rescue => e
         $stderr.puts e.message
      end
      sleep 1
   end
rescue Interrupt
   $stderr.puts "caught CTRL+C"
end
