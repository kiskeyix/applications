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
#
# == TODO
# - allow uploading up to six files from the command line: ./fotolog_http_upload.rb ... file1 [file2[...]]
#
# == exit code
# 0 - Ok
#
# 1 - Error

=begin
$Revision: 1.0 $
$Date: 2009-04-09 18:36 EDT $
Luis Mondesi <lmondesi@fotolog.biz>

DESCRIPTION:
USAGE: fotolog_http_upload --help
LICENSE: GPL
=end

require 'net/http'
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

# helpers:

# given a form input name returns the right POST data
# you still need your boundaries before this
def upload_form(key,content)
   return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"\r\n" +
   "\r\n" +
   "#{content}\r\n"
end

# given a form file input name returns the right POST data
# you still need your boundaries before this
def file_to_multipart(key,filename,mime_type,content)
   return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{File.basename(filename)}\"\r\n" +
   "Content-Transfer-Encoding: binary\r\n" +
   "Content-Type: #{mime_type}\r\n" +
   "\r\n" +
   "#{content}\r\n"
end

# internal vars:
url = 'photo.fotolog.com'
path = '/upload'
loginurl = 'account.fotolog.com'
loginpath = '/login'
useragent = 'Ruby/1.8 (Fotolog; LM)'
boundary = '-------------------------3599464642501006571963510995'

# 1. get cookie from login form
http = Net::HTTP.new(loginurl, 80)
data = 'u_name=' + CGI::escape(user) + '&p_word=' + CGI::escape(password)
headers = {
   'Content-Type' => 'application/x-www-form-urlencoded',
   'User-Agent' => useragent
}
resp = http.post(loginpath, data, headers)
# cookie is now has P and LEC
cookie = resp.response['set-cookie']

# debug
#puts 'Code = ' + resp.code
#puts 'Message = ' + resp.message
#resp.each {|key, val| puts key + ' = ' + val}
#puts cookie
#exit 0
# end debug

# 2. read our file in memory
# TODO will need to loop through file list
content = open( file, "rb" ) do |f|
   f.read()
end

# 3. set headers for our multipart/form-data post request
headers2 = {
   'Cookie'              => cookie,
   'Referer'             => 'http://photo.fotolog.com/upload',
   'Content-Type'        => 'multipart/form-data; boundary='+boundary,
   'Accept-Language'     => 'en-us,en;q=0.5',
   'Accept-Encoding'     => 'gzip,deflate',
   'Keep-Alive'          => '300',
   'Connection'          => 'keep-alive',
   'User-Agent'          => useragent
}

# 4. upload file
# - the form needs u= (user) and password= (password) the rest is optional
# - you may add multiple images by adding calls to file_to_multipart() (think array)
params = [ upload_form('u',user), file_to_multipart('image',file,'image/jpeg',content), upload_form('password',password) ]
query = params.collect {|p| '--' + boundary + "\r\n" + p }.join('') + "--" + boundary + "--\r\n"
http = Net::HTTP.new(url, 80)
#http.set_debug_output $stderr

start_time = Time.now
resp = http.post2(path,query,headers2)
end_time = Time.now
elapsed_time = end_time - start_time

#system  "wget --load-cookies tcook.txt --post-data="delete=43839074&pwd=testtest101" http://photo.fotolog.com/archive"

case resp
when Net::HTTPRedirection
   puts resp['location'] + " (#{elapsed_time})"
   exit 0
when Net::HTTPSuccess, Net::HTTPFound
   puts "Ok" + " (#{elapsed_time})"
   exit 0
else
   resp.error!
   exit 1
end
