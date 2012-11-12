#!/usr/bin/env ruby

require File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', '..', '..', 'puppetdb', 'puppet', 'lib', 'puppet', 'util', 'puppetdb', 'char_encoding')

require 'benchmark'

def time_file(file_path)
  f = File.new(file_path)

  puts "Analyzing '#{file_path}' (size #{f.size / 1024}k)."

  str = f.read

  puts "Finished reading file into memory"

  puts "IConv: " << Benchmark.measure { Puppet::Util::Puppetdb::CharEncoding.send(:iconv_to_utf8, str) } .to_s
  puts "1.8: " << Benchmark.measure { Puppet::Util::Puppetdb::CharEncoding.send(:ruby18_manually_clean_utf8, str) } .to_s
  puts "1.8: " << Benchmark.measure { Puppet::Util::Puppetdb::CharEncoding.send(:ruby18_manually_clean_utf8, str) } .to_s
  puts "Composite: " << Benchmark.measure { Puppet::Util::Puppetdb::CharEncoding.send(:ruby18_manually_clean_utf8, Puppet::Util::Puppetdb::CharEncoding.send(:iconv_to_utf8, str)) } .to_s
  puts "Composite2: " << Benchmark.measure { Puppet::Util::Puppetdb::CharEncoding.send(:iconv_to_utf8, Puppet::Util::Puppetdb::CharEncoding.send(:ruby18_manually_clean_utf8, str)) } .to_s


  #puts "times: #{time18}, #{timeIconv}, #{timeComposite}"


end

files = [
    #"/opt/software/java/jdk1.6.0_31/db/docs/pdf/tools/derbytools.pdf",
    #"/opt/software/java/jdk1.6.0_31/db/docs/pdf/getstart/getstartderby.pdf",
    #"/opt/software/java/jdk1.6.0_31/db/docs/pdf/devguide/derbydev.pdf",
    #"/opt/software/java/jdk1.6.0_31/db/docs/pdf/ref/refderby.pdf",
    "/home/cprice/Downloads/farmville-web-fbpr-10-202-247-94.int.ec2.zynga.com.json",
]

files.each { |f| time_file(f) }

#end
#
#puts "\n"
#puts "Analyzing: " + readable_hex_bytes(bytes).join(" ")
#
#str = bytes.pack("C*").force_encoding('UTF-8')
#puts "string length: '#{str.length}', encoding: '#{str.encoding}'"
#
#codepoint = "NaN"
#
#begin
#  codepoints = []
#  str.codepoints.each do |i|
#    #puts "Codepoint: #{i}"
#    codepoints << i
#  end
#  raise "Expected exactly one codepoint, found '#{codepoints.length}'!!" unless codepoints.length == 1
#  codepoint = codepoints[0]
#rescue ArgumentError
#  # should check the string, but this is probably "invalid byte sequence"
#end
#
#puts "codepoint: #{codepoint}"
#
#byte_strings = separated_byte_strings(bytes.map { |b| sprintf("%08b", b) })
##byte_strings = bytes.map { |b| sprintf("%08b", b) }
#puts "bytes: " + byte_strings.map{ |hash| "#{hash[:prefix]}#{hash[:colorized]}" }.join(" ")
#
#
#calculated_codepoint = byte_strings.map{ |hash| hash[:significant] }.join("").to_i(2)
#puts "calculated codepoint: " + byte_strings.map{ |hash| hash[:colorized] }.join("") +
#    " = #{calculated_codepoint}"
#
#if ((codepoint != "NaN") && (calculated_codepoint != codepoint))
#  raise "Codepoint (#{codepoint}) and calculated codepoint (#{calculated_codepoint}) do not match!"
#end
#
#str = bytes.pack('c*')
#
##puts "ORIGINAL STRING encoding: '#{str.encoding}'"
#
## This will trigger the ruby 1.9 code path
#cleaned_19 = Puppet::Util::Puppetdb::CharEncoding.utf8_string(str)
#cleaned_18 = Puppet::Util::Puppetdb::CharEncoding.send(:ruby18_manually_clean_utf8, str)
#cleaned_18_iconv = Puppet::Util::Puppetdb::CharEncoding.send(:iconv_to_utf8, str)
#
#puts "Ruby 1.9: " + readable_hex_bytes(cleaned_19.unpack("C*")).join(" ")
#puts "Ruby 1.8: " + readable_hex_bytes(cleaned_18.unpack("C*")).join(" ")
#puts "IConv   : " + readable_hex_bytes(cleaned_18_iconv.unpack("C*")).join(" ")
#
