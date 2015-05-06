require './rubick.rb'

class BadParameterException < Exception
end

PARAMS = ['-r', '-p', '-a']

def read_params
  result = {}
  i = 0
  while i < ARGV.size do
    param = ARGV[i]
    if PARAMS.include? param then
      value = ARGV[i+1]
    else
      raise BadParameterException, "Wrong parameter: #{param.to_s}."
    end # if
    case param
      when '-r'
        if !value.nil? and File.directory? value then
          result['root'] = value
          i += 2
          next
        elsif value.nil?
          raise BadParameterException, "Parameter Error. (#{param.to_s}). No root directory specified."
        else
          raise BadParameterException, "Parameter Error. (#{param.to_s}). Directory #{value.to_s} doesn't exist."
        end # if
      when '-p'
        if value.to_i.to_s == value then
          result['port'] = value
          i += 2
          next
        elsif value.nil?
          raise BadParameterException, "Parameter Error. (#{param.to_s}). No port number specified."
        else
          raise BadParameterException, "Parameter Error. (#{param.to_s}). #{value.to_s} is not a valid port number."
        end # if
      when '-a'
        if !value.nil? then # TODO: Check if a valid address
          result['address'] = value
          i += 2
        elsif value.nil?
          raise BadParameterException, "Parameter Error. (#{param.to_s}). No address specified."
        else
          raise BadParameterException, "Parameter Error. (#{param.to_s}). #{value.to_s} is not a valid address."
        end # if
      else
        i += 1 # just in case an infinite loop happens
    end # case
  end # while
  return result
end # read_params


begin
  if ARGV.size == 0 then
    server = Rubick.new
    server.run
  else
    config = read_params
    server = Rubick.new
    server.configure config
    server.run
  end
rescue BadParameterException => msg
  puts msg.message
  puts "Rubick v#{Rubick::VERSION.to_s}\nUsage: ruby rubick.rb [OPTIONAL PARAMETERS]"
  puts "Parameters are: \n-p PORT NUMBER\n-r ROOT DIRECTORY\n-a ADDRESS (IP OR DOMAIN)"
rescue BadConfigException => msg
  puts msg.message
  puts "Please ensure your config file is correct."
ensure
  server.stop unless server.nil?
end