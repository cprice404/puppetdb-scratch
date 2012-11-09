#!/usr/bin/env ruby

require File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', '..', '..', 'puppetdb', 'puppet', 'lib', 'puppet', 'util', 'puppetdb', 'char_encoding')

ruby_version = RUBY_VERSION.split('.')
raise "This script must be run in ruby 1.9!" unless (ruby_version[0..1] == ["1", "9"])

Utf8ReplacementChar = [ 0xEF, 0xBF, 0xBD ]

def readable_hex_bytes(bytes)
  bytes.map {|b| sprintf("0x%02x", b) }
end

def readable_hex_string(str)
  result = []

  str.each_byte { |b| result << sprintf("0x%02x", b) }

  result.join(" ")
end

def remove_replacement_chars(bytes)
  bytes = bytes.clone
  while (start = bytes.index(Utf8ReplacementChar[0]))
    if (bytes[start..start+2] == Utf8ReplacementChar)
      bytes.slice!(start, 3)
    end
  end
  bytes
end


tested_count = 0
failures_map = {}
failures_count = 0

#(0..0xffff).each do |i|
(0..0xffffff).each do |i|
  tested_count += 1
  bytes = [i].pack('N').unpack("C*")
  bytes.delete_if {|b| b == 0 }



  str = bytes.pack('c*')

  #puts "ORIGINAL STRING encoding: '#{str.encoding}'"

  # This will trigger the ruby 1.9 code path
  cleaned_19 = Puppet::Util::Puppetdb::CharEncoding.utf8_string(str)
  #cleaned_18 = Puppet::Util::Puppetdb::CharEncoding.send(:ruby18_clean_utf8, str)
  cleaned_18 = Puppet::Util::Puppetdb::CharEncoding.send(:iconv_to_utf8, str)

  bytes_19 = cleaned_19.unpack("C*")
  bytes_18 = cleaned_18.unpack("C*")

  #if (bytes_19 != bytes_18)
  if (remove_replacement_chars(bytes_19) != remove_replacement_chars(bytes_18))
    pair = [readable_hex_bytes(bytes_18), readable_hex_bytes(bytes_19)]
    failures_map[pair] ||= []
    failures_map[pair] << bytes
    failures_count += 1

    #puts "THEY DON'T MATCH: '#{cleaned_19.class},#{cleaned_19.inspect}', '#{cleaned_18.class}#{cleaned_18.inspect}'"
    #
    #puts "bytes 19: '#{bytes_19}', '#{cleaned_19.encoding}'"
    #puts "bytes 18: '#{bytes_18}', '#{cleaned_18.encoding}'"
    #
    #output = "#{i}: #{bytes.map {|b| sprintf("0x%02x", b)} .join(" ")}"
    #output << " 1.9: '#{readable_hex_string(cleaned_19)}'"
    #output << " 1.8: '#{readable_hex_string(cleaned_18)}'"
    #puts output
  end

end

failures_map.keys.sort_by {|key| failures_map[key].length} .each do |key|
  puts "\t#{key}: #{failures_map[key].length} occurrences (" +
      failures_map[key][0..4].map { |bytes|
        readable_hex_bytes(bytes).join(" ").inspect
      }.join(",") + ((failures_map[key].length > 5) ? "..." : "") + ")"
end

puts "Detected #{failures_map.length} types of failures."
puts "#{failures_count}/#{tested_count} total discrepant byte sequences."

puts "Done."

