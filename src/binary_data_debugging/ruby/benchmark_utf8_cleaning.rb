require 'puppet/util/puppetdb/char_encoding'
require 'puppet'
#require 'puppet/error'
#require 'puppet/util'
#require 'puppet/util/logging'

puts "Hi"

#cat = File.read("/bin/cat")
#cat = File.read("/home/cprice/Downloads/heat_map.gif")
cat = File.read("/home/cprice/Downloads/GWU625_linux_v2.6.0006.20100625.zip")

Benchmark.bmbm do |x|
  x.report("ruby18") { Puppet::Util::Puppetdb::CharEncoding.ruby18_clean_utf8(cat) }
  x.report("ruby19") { cat.each_char.map { |c| c.valid_encoding? ? c : "\ufffd"}.join }
end

