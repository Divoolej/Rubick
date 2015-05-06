require 'socket'

class BadConfigException < Exception
end

class Rubick
  self::VERSION = 0.3
  
  public
    def initialize # the constructor method initializes the variables and loads the configuration from a file
      @config = {}
      load_config
    end #initialize
  
    def run # the main body of the server
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
          puts response
          client.close # close connection
        end # Thread.start
      end # loop
    end # run
    
    def stop # stops the server
    end #stop
    
    def configure cfg # alters the @config field with user given parameters
      cfg.each { |key, value|
        @config[key] = value
      } # cfg.each
    end # configure
  
  private
  
    def process_request request # process the HTTP request from browser
      response = "HTTP/1.1 200 OK\n"
      date = Time.now.gmtime.strftime("%a, %e %b %Y %H:%M:%S GMT\n")
      response += date
      response += "Connection: close\n"
      response += "Server: Rubick/#{VERSION}\n"
      response += "Content-Type: text/html\n"
      requested_file = request.split[1]
      return requested_file
    end # process_request
    
    def load_config # loads the server configuration from the config file 'rubick.cfg'
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