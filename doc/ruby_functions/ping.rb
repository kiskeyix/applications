#!/usr/bin/env ruby

=begin
$Revision: 1.0 $
$Date: 2011-09-07 16:30 EDT $
Luis Mondesi <lemsx1@gmail.com>

DESCRIPTION:
USAGE: ping.rg --help
LICENSE: ___
=end

begin
   require 'net/ping'
   times = []
   1.upto(1000) do |t|
      print "try  #{t} in "
      s = Time.now
      obj = Net::Ping::ICMP.new(ARGV[0])
      obj.timeout = 0.0001
      obj.ping
      e = Time.now - s
      if obj.duration
         times << obj.duration
      else
         times << 0
      end
      puts "#{obj.duration} s (#{e})"
   end
   avg = times.reduce(:+) / times.size
   puts "avg #{avg}"

rescue => e
   $stderr.puts e.message
end
