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
          if value.to_s.downcase == 'any' then
            result['address'] = ''
          else
            result['address'] = value
          end
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