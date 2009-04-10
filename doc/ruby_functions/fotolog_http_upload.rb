#!/usr/bin/env ruby
# == Synopsis
#
# fotolog_http_upload: allows uploading photos to Fotolog, Inc.
#
# References:
# - http://www.realityforge.org/articles/2006/03/02/upload-a-file-via-post-with-net-http
# - http://www.mail-archive.com/cactus-user@jakarta.apache.org/msg06500.html
# - http://www.ietf.org/rfc/rfc1867.txt
#
# == Usage
#
# fotolog_http_upload [OPTION] <--user STRING> <--password STRING> <--file FILENAME |FILENAME>
#
# -h, --help:
#    show help
#
# --usage, -U, -?:
#    show usage
#
# --user USER
#    username to login with
#
# --password PASSWORD
#    password to use
#
# --file FILENAME or FILENAME
#    file to upload

=begin
$Revision: 1.0 $
$Date: 2009-04-09 18:36 EDT $
Luis Mondesi <lmondesi@fotolog.biz>

DESCRIPTION:
USAGE: fotolog_http_upload --help
LICENSE: GPL
=end

require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
[ '--help', '-h', GetoptLong::NO_ARGUMENT ],
[ '--usage', '-U', '-?', GetoptLong::NO_ARGUMENT ],
[ '--user', GetoptLong::OPTIONAL_ARGUMENT ],
[ '--password', GetoptLong::OPTIONAL_ARGUMENT ],
[ '--file', GetoptLong::OPTIONAL_ARGUMENT ]
)

user = nil
password = nil
file = nil
opts.each do |opt, arg|
   case opt
   when '--help'
      RDoc::usage
   when '--usage'
      RDoc::usage
   when '--user'
      if arg == ''
         puts "user argument missing (try --help)"
         RDoc::usage 1
         exit 1 # never reaches here
      else
         user = arg
      end
   when '--password'
      if arg == ''
         puts "password argument missing (try --help)"
         RDoc::usage 1
         exit 1 # never reaches here
      else
         password = arg
      end
   when '--file'
      if arg == ''
         puts "file argument missing (try --help)"
         RDoc::usage 1
         exit 1 # never reaches here
      else
         file = arg
      end
   end
end
if ARGV.length > 0
   file = ARGV.shift
end
# sanity checks:
if user.nil? or password.nil? or file.nil?
   RDoc::usage 1
   exit 1 # never reaches here
end

require 'net/http'
def file_to_multipart(key,filename,mime_type,content,user=nil)
   #u=\"#{CGI::escape(user)}\"; 
   return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
   "Content-Transfer-Encoding: binary\r\n" +
   "Content-Type: #{mime_type}\r\n" +
   "\r\n" +
   "#{content}\r\n"
end

# internal vars:
url = 'photo.fotolog.com'
path = '/upload'
useragent = 'Ruby/1.8 (Fotolog; LM)'
boundary = '4aa7438b5c6fd25599785dd25a41be96' # md5sum of what?

# 1. get cookie
http = Net::HTTP.new(url, 80)
# GET request -> so the host can set his cookies
resp = http.get(path, nil)
cookie = resp.response['set-cookie']

# 2. POST request -> logging in
data = 'u_name=' + user + '&p_word=' + password
headers = {
   'Cookie' => cookie,
   'Referer' => 'http://'+ url + path,
   'Content-Type' => 'application/x-www-form-urlencoded',
   'User-Agent' => useragent
}
resp = http.post(path, data, headers)

# debug
#puts 'Code = ' + resp.code
#puts 'Message = ' + resp.message
#resp.each {|key, val| puts key + ' = ' + val}
# end debug

# 3. read our file in memory
content = open( file, "rb" ) do |f|
   f.read()
end

# 4. set headers for our multipart/form-data post request
headers2 = {
   'Cookie'              => cookie,
   'Referer'             => 'http://photo.fotolog.com/upload',
   'Content-Type'        => 'multipart/form-data',
   'boundary'            => boundary,
   'User-Agent'          => useragent
}

# 5. upload file
#params = [ file_to_multipart('file',file,'image/jpeg',content,user) ]
#query = params.collect {|p| p + '--' + boundary + "\r\n" }.join('') + "--" + boundary + "--\r\n"
query = '--' + boundary + "\r\n" + file_to_multipart('image',file,'image/jpeg',content,user) + '--' + boundary + "--\r\n"
http.set_debug_output $stderr
resp = http.post2(path,query,headers2)

case resp
when Net::HTTPSuccess, Net::HTTPRedirection
   # OK
   puts "File uploaded " + resp.status
else
   resp.error!
end
