#!/usr/bin/env ruby

require File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', '..', '..', 'puppetdb', 'puppet', 'lib', 'puppet', 'util', 'puppetdb', 'char_encoding')

unless ARGV[0]
  raise "Usage: print_file_as_hex.rb <BINARY_FILE_PATH>"
end

binary_data_file = ARGV[0]
unless File.exists?(binary_data_file)
  raise "Unable to find specified file '#{binary_data_file}'"
end

f = File.new(binary_data_file)
bytes = []
f.each_byte do |b|
  bytes << b
end

puts "Original bytes: " + bytes.map{ |b| sprintf("0x%02x", b) }.join(" ")


bytes = File.read(binary_data_file)

cleaned = Puppet::Util::Puppetdb::CharEncoding.utf8_string(bytes)

result = []

#cleaned.each_char { |b| result << "0x#{b.unpack('H*')}" }
cleaned.each_byte { |b| result << sprintf("0x%02x", b) }

puts "Cleaned bytes: " + result.join(" ")
