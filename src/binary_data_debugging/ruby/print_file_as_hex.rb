#!/usr/bin/env ruby

require File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', '..', '..', 'puppetdb', 'puppet', 'lib', 'puppet', 'util', 'puppetdb', 'char_encoding')

unless ARGV[0]
  raise "Usage: print_file_as_hex.rb <BINARY_FILE_PATH>"
end

binary_data_file = ARGV[0]
unless File.exists?(binary_data_file)
  raise "Unable to find specified file '#{binary_data_file}'"
end

bytes = File.read(binary_data_file)

cleaned = Puppet::Util::Puppetdb::CharEncoding.utf8_string(bytes)

result = []

#cleaned.each_char { |b| result << "0x#{b.unpack('H*')}" }
cleaned.each_byte { |b| result << sprintf("0x%02x", b) }

puts result.join(" ")
