# Copyright 2015 Wojciech Olejnik ("Divoolej")

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'socket'

class BadConfigException < Exception
end

class Rubick
  self::VERSION = 0.5
  
  public
  
    # The constructor method initializes the variables and loads the configuration from a file.
    def initialize
      @config = {}
      load_config
    end #initialize
  
  
    # This method is the main body of the server, it creates an infinite loop and handles the upcoming connections.
    def run
      puts @config
      port = @config['port'].to_i
      addr = @config['address']
      @socket = TCPServer.new(addr, port) # create the server socket
      puts "Rubick HTTP Server v#{VERSION} running at #{addr} on port #{port}."
      loop do
        Thread.start(@socket.accept) do |client| # for each client start a new thread which handles their requests
          client_ip = client.remote_address.ip_address.to_s
          puts "#{client_ip} is accepted" # log that a client connected
          message = client.recv(2048) # read the request
          puts client_ip + " => " + message # log the request
          response = process_request message # process the request and create a response
          client.write response
          client.close # close connection
        end # Thread.start
      end # loop
    end # run
    
    
    # This method stops the server.
    def stop
    end #stop
    
    
    # This method alters the @config fields with user given parameters.
    def configure cfg
      cfg.each { |key, value| # for each key-value pair of user-given parameters
        @config[key] = value # override the default settings with those given by the user
      } # cfg.each
    end # configure
  
  private
  
    # This method recognizes the HTTP method in the client's request and returns an adequate response.
    def process_request request # process the HTTP request received from browser
      method = request.split[0] # retrieve the method name from the request
      if method == "GET" then # if the method is GET
        return http_get request # process the GET request
      elsif method == "HEAD" then # if the method is HEAD
        return http_head request # process the HEAD request
      else # other methods are not supported
        return method_not_allowed_405 method # in case of an unsupported method, return the appropriate status code in a response
      end # if
    end #process_request
    
    
    # This method processes the GET method and creates a complete response.
    def http_get request
      response = http_head request # check for file existance and generate the header
      if response.split[1] != "200" then # if the status code is not "200 OK" then return it, because there was an error
        return response
      end
      
      requested_file = request.split[1] # get the requested resource name
      if requested_file[-1] == '/' then
        if File.file? @config['root'] + requested_file + 'index.html' then # check if the index file has '.html' extension
          requested_file += 'index.html' # add the appropriate file to the requested file path
        else
          requested_file += 'index.htm' # ^
        end # if
      end # if
      
      file = File.new(@config['root'] + requested_file, 'r') # open the requested file
      content = file.read # read the file's content
      response += content # append it to the response
      file.close # close the requested file
      return response # return the complete response
    end # http_get
    
    
    # This method creates a header of a response for the given request (which is by itself a whole response for the HEAD method), which is further used in the http_get method. This method also checks the existance of the requested resources and possibly generates an error response.
    def http_head request
      requested_file = request.split[1] # get the requested resource name
      if requested_file[-1] == '/' then
        if File.file? @config['root'] + requested_file + 'index.htm' then # check if the index file has '.html' extension
          requested_file += 'index.htm' # add the appropriate file to the requested file path
        else
          requested_file += 'index.html' # ^
        end # if
      end # if
      
      if not File.exist? @config['root'] + requested_file then # check whether the file exists
        return not_found_404 requested_file # if it doesn't, return the "404 NOT FOUND" response
      end
      
      if not File.readable? @config['root'] + requested_file then # check if the requested resource is readable
        return forbidden_403 requested_file # if it's not, return the "403 FORBIDDEN" response
      end
      
      content_type = recognize_content_type requested_file # recognize the content type of the resource
      if content_type.nil? then # if the content type was not recognized
        return unsupported_media_type_415 requested_file # return the "415 UNSUPPORTED MEDIA TYPE" response
      end
      
      # serve the requested resource
      response = "HTTP/1.1 200 OK\n" # the status message
      date = Time.now.gmtime.strftime("%a, %e %b %Y %H:%M:%S GMT\n") # current time and date
      response += date # ^
      response += "Connection: close\n" # information that this response closes the connection with client
      response += "Server: Rubick/#{VERSION}\n" # information about the server
      
      response += "Content-Type: #{content_type}\n"
      file = File.new @config['root'] + requested_file # open the requested file
      content = file.read # read the content of the resource
      response += "Content-Length: #{content.length}\n\n"
      file.close # close the file
      
      return response # return the complete header
    end # http_head
    
    
    def not_found_404 resource
      response = "HTTP/1.1 404 Not Found\n" # the status message
      date = Time.now.gmtime.strftime("%a, %e %b %Y %H:%M:%S GMT\n") # current time and date
      response += date # ^
      response += "Connection: close\n" # information that this response closes the connection with client
      response += "Server: Rubick/#{VERSION}\n" # information about the server
      response += "Content-Type: text/html\n"
      if File.file? @config['root'] + '404.html' then # if there is a custom html file for the "404 Not Found" error
        file = File.new @config['root'] + '404.html' # open the file
        content = file.read # read the content of the resource
        response += "Content-Length: #{content.length}\n\n"
        file.close # close the file
      else # otherwise, return a default error page
        error = "<!DOCTYPE HTML><html><head><title>404 Not Found</title></head><body><h1>404 Not Found</h1><p>Sorry, but the requested resource: #{resource} was not found on the server.</p></body></html>"
        response += "Content-Length: #{error.length}\n\n"
        response += error
      end
      
      return response # return the complete error response
    end
    
    
    def forbidden_403 resource
      response = "HTTP/1.1 403 Forbidden\n" # the status message
      date = Time.now.gmtime.strftime("%a, %e %b %Y %H:%M:%S GMT\n") # current time and date
      response += date # ^
      response += "Connection: close\n" # information that this response closes the connection with client
      response += "Server: Rubick/#{VERSION}\n" # information about the server
      response += "Content-Type: text/html\n"
      
      error = "<!DOCTYPE HTML><html><head><title>403 Forbidden</title></head><body><h1>403 Forbidden</h1><p>Sorry, but you don't have the right to read the requested resource: #{resource}</p></body></html>"
      response += "Content-Length: #{error.length}\n\n"
      response += error
      
      return response
    end
    
    
    def unsupported_media_type_415 resource
      response = "HTTP/1.1 415 Unsupported Media Type\n" # the status message
      date = Time.now.gmtime.strftime("%a, %e %b %Y %H:%M:%S GMT\n") # current time and date
      response += date # ^
      response += "Connection: close\n" # information that this response closes the connection with client
      response += "Server: Rubick/#{VERSION}\n" # information about the server
      response += "Content-Type: text/html\n"
      
      error = "<!DOCTYPE HTML><html><head><title>415 Unsupported Media Type</title></head><body><h1>415 Unsupported Media Type</h1><p>Sorry, but the type of the requested resource: #{resource} is not supported by the server.</p></body></html>"
      response += "Content-Length: #{error.length}\n\n"
      response += error
      
      return response
    end
    
    
    def method_not_allowed_405 method
      response = "HTTP/1.1 405 Method Not Allowed\n" # the status message
      date = Time.now.gmtime.strftime("%a, %e %b %Y %H:%M:%S GMT\n") # current time and date
      response += date # ^
      response += "Connection: close\n" # information that this response closes the connection with client
      response += "Server: Rubick/#{VERSION}\n" # information about the server
      response += "Content-Type: text/html\n"
      
      error = "<!DOCTYPE HTML><html><head><title>405 Method Not Allowed</title></head><body><h1>405 Method Not Allowed</h1><p>Sorry, but method #{method} is not allowed by the server.</p></body></html>"
      response += "Content-Length: #{error.length}\n\n"
      response += error
      
      return response
    end
    
    
    # This method generates the value for the "Content-Type" key in the HTTP response header based on the extension of the requested file
    def recognize_content_type file
      ext = file.split('.')[-1].downcase # extract the file's extension
      if ext == 'jpg' or ext == 'jpeg' then # image
        return 'image/jpeg'
      elsif ext == 'gif' then
        return 'image/gif'
      elsif ext == 'png' then
        return 'image/png'
      elsif ext == 'js' then # application
        return 'application/js'
      elsif ext == 'xhtml' then
        return 'application/xhtml+xml'
      elsif ext == 'json' then
        return 'application/json'
      elsif ext == 'mp3' then # audio
        return 'audio/mpeg'
      elsif ext == 'wma' then
        return 'audio/x-ms-wma'
      elsif ext == 'wav' then
        return 'audio/x-wav'
      elsif ext == 'txt' then # text
        return 'text/plain'
      elsif ext == 'html' or ext == 'htm' then
        return 'text/html'
      elsif ext == 'css' then
        return 'text/css'
      elsif ext == 'xml' then
        return 'text/xml'
      elsif ext == 'mpeg' then # video
        return 'video/mpeg'
      elsif ext == 'mp4' then
        return 'video/mp4'
      elsif ext == 'wmv' then
        return 'video/x-ms-wmv'
      else
        return nil
      end
    end # recognize_content_type
    
    
    # This method loads the server configuration from the config file 'rubick.cfg'
    def load_config
      cfg = File.new('rubick.cfg', 'r') # open the config file
      begin
        loop do # loop through the config file
          key = cfg.gets # get the next key from the config file
          break if key.nil? # break if there is an EOF
          key.chomp! # remove the whitespace from key
          key.chop! if key[-1] == ":" # remove the colon if present
          value = cfg.gets # get the value for the key from the config file
          if value.nil? or value[-1] == ":" then # if a key is read instead of value (keys end with a colon) or if there is an EOF
            raise BadConfigException, "Config Error. No value for key #{key}."
          else
            value.chomp! # remove whitespace from value
          end # if
          @config[key] = value # add the key and the value to the @config field
        end # loop
      ensure # ensure the file is closed
        cfg.close # close the config file
      end # begin-ensure
    end # load_config
end # Rubick