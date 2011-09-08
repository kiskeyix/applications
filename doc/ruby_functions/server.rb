#!/usr/bin/env ruby
# Use this server to test latency. See client.rb
# On a loopback interface this happens in 0.0002012 seconds
# (0.2ms)
#
# Luis Mondesi <lemsx1@gmail.com>
# 2011-09-08 14:37 EDT

require 'socket'
serv = TCPServer.new(8000)
begin
   puts "server"
   loop do
      begin # emulate blocking accept
         sock = serv.accept_nonblock
         sock.puts "#{Time.now.to_f}"
      rescue IO::WaitReadable, Errno::EINTR
         #      puts "retrying..."
         IO.select([serv])
         retry
      end
   end
rescue Interrupt
   $stderr.puts "caught CTRL+C"
end
