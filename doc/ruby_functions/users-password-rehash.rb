#!/usr/bin/env ruby

USERS=%w[

root:plain_text_here

]

def random_salt(n)
  universe = ('a'..'z').to_a
  universe += ('A'..'Z').to_a
  universe += ('0'..'9').to_a
  universe += %w[ / = ]
  str = ""
  n.times do
    str += universe[rand universe.size]
  end
  str
end

begin
  USERS.each do |user|
    user, password = user.split(/:/)
    puts "%s: %s" % [user, password.crypt("$6$%s$" % random_salt(8))]
  end
rescue => e
  $stderr.puts e.message
  $stderr.puts e.backtrace.join("\n")
end

