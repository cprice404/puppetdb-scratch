#!/usr/bin/env ruby

require 'colorize'
require File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', '..', '..', 'puppetdb', 'puppet', 'lib', 'puppet', 'util', 'puppetdb', 'char_encoding')

ruby_version = RUBY_VERSION.split('.')
raise "This script must be run in ruby 1.9!" unless (ruby_version[0..1] == ["1", "9"])


bytes = [0xe0, 0x8b, 0x84]


def readable_hex_bytes(bytes)
  bytes.map {|b| sprintf("0x%02x", b) }
end

NumPrefixBits = [[1],
                 [3,2],
                 [4, 2, 2],
                 [5, 2, 2, 2],
                 [6, 2, 2, 2, 2],
                 [7, 2, 2, 2, 2, 2]]

def separated_byte_strings(byte_strings)
  colors = [:red, :green, :blue, :purple]
  color_index = 0

  prefix_bits = NumPrefixBits[byte_strings.length - 1]

  separated = []

  byte_strings.each_index do |i|
    byte_string = byte_strings[i]
    signficant = byte_string[prefix_bits[i], 8 - prefix_bits[i]]
    result = {:prefix      => byte_string[0, prefix_bits[i]],
              :significant => signficant,
              :colorized   => signficant.send(colors[color_index]),
            }
    color_index += 1
    separated << result
  end

  separated
end

puts "\n"
puts "Analyzing: " + readable_hex_bytes(bytes).join(" ")

str = bytes.pack("C*").force_encoding('UTF-8')
puts "string length: '#{str.length}', encoding: '#{str.encoding}'"

codepoint = "NaN"

begin
  codepoints = []
  str.codepoints.each do |i|
    #puts "Codepoint: #{i}"
    codepoints << i
  end
  raise "Expected exactly one codepoint, found '#{codepoints.length}'!!" unless codepoints.length == 1
  codepoint = codepoints[0]
rescue ArgumentError
  # should check the string, but this is probably "invalid byte sequence"
end

puts "codepoint: #{codepoint}"

byte_strings = separated_byte_strings(bytes.map { |b| sprintf("%08b", b) })
#byte_strings = bytes.map { |b| sprintf("%08b", b) }
puts "bytes: " + byte_strings.map{ |hash| "#{hash[:prefix]}#{hash[:colorized]}" }.join(" ")


calculated_codepoint = byte_strings.map{ |hash| hash[:significant] }.join("").to_i(2)
puts "calculated codepoint: " + byte_strings.map{ |hash| hash[:colorized] }.join("") +
    " = #{calculated_codepoint}"

if ((codepoint != "NaN") && (calculated_codepoint != codepoint))
  raise "Codepoint (#{codepoint}) and calculated codepoint (#{calculated_codepoint}) do not match!"
end

str = bytes.pack('c*')

#puts "ORIGINAL STRING encoding: '#{str.encoding}'"

# This will trigger the ruby 1.9 code path
cleaned_19 = Puppet::Util::Puppetdb::CharEncoding.utf8_string(str)
cleaned_18 = Puppet::Util::Puppetdb::CharEncoding.send(:ruby18_clean_utf8, str)
cleaned_18_iconv = Puppet::Util::Puppetdb::CharEncoding.send(:iconv_to_utf8, str)

puts "Ruby 1.9: " + readable_hex_bytes(cleaned_19.unpack("C*")).join(" ")
puts "Ruby 1.8: " + readable_hex_bytes(cleaned_18.unpack("C*")).join(" ")
puts "IConv   : " + readable_hex_bytes(cleaned_18_iconv.unpack("C*")).join(" ")

