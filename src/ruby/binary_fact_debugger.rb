#!/usr/bin/env ruby

require 'puppet'
require 'puppet/util/puppetdb'
require 'puppet/network/http_pool'

Puppet.parse_config
Puppet[:confdir] = "/home/cprice/work/puppet/test/client/conf"
Puppet[:vardir] = "/home/cprice/work/puppet/test/client/var"

class ThisIsStupid
  include Puppet::Util::Puppetdb

  BunkRequest = Struct.new(:server, :port, :key)

  # A `#submit_command` method that doesn't require an `Indirector::Request`
  #  argument.
  def submit_command(key, payload, command, version)
    bunk_request = BunkRequest.new("cosmicshame.puppetlabs.lan", 8081, key)
    # call into the "real" `#submit_command` method in `Puppet::Util::Puppetdb`
    super(bunk_request, payload, command, version)
  end

  def http_post(bunk_request, path, body, headers)
    http = Puppet::Network::HttpPool.http_instance(bunk_request.server, bunk_request.port)
    http.post(path, body, headers)
  end

end

def submit_file(filepath)
  data = File.read(filepath)
  puts "DATA LENGTH: '#{data.length}'"
  submit_data(data, 0, data.length - 1)
end

def submit_data(data, start_offset, end_offset)
  submitter = ThisIsStupid.new
  submitter.submit_command("dumb", data[start_offset..end_offset], "replace facts", 1)
end

def find_first_success(data, start_offset, end_offset, next_offsets_fn)
  while true
    begin
      puts "Trying #{start_offset}-#{end_offset}"
      submit_data(data, start_offset, end_offset)
      break [start_offset, end_offset]
    rescue Puppet::Error => e
      puts "Submission failed: '#{e}'"
        start_offset, end_offset = next_offsets_fn.call(start_offset, end_offset)
    end
  end
end

def find_smallest_failure(file)
  data = File.read(file)
  start_offset, end_offset = find_first_success(data, 0, data.length, lambda { |x,y| [x, y - 1] } )

  if start_offset == 0 and end_offset == data.length
    raise RuntimeError, "This binary data passes the checksum, unable to find failure case."
  end

  puts "First successful substring working backwards from end: 0-#{end_offset}"

  start_offset, end_offset = find_first_success(data, 0, end_offset + 1, lambda { |x,y| [x + 1, y] })

  puts "First successful substring working forwards from start: #{start_offset}-#{end_offset}"


  puts "Should fail with #{start_offset - 1}-#{end_offset}, trying."

  begin
    submit_data(data, start_offset - 1, end_offset)
    raise RuntimeError, "DOH!  Expected the submission of range #{start_offset - 1}-#{end_offset} to fail, but it didn't!"
  rescue Puppet::Error => e
    puts "yup, that failed."
    filepath = "./#{`uuidgen`.strip}.bunk"
    puts "Writing bad data to file: '#{filepath}'"
    File.open(filepath, "w") do |file|
      file.write(data[(start_offset - 1)..(end_offset)])
    end
    return filepath
  end
end


result_file = find_smallest_failure("../../data/binary_fact_sample/initial_monmap")

puts "Double-checking result file ('#{result_file}'"
begin
  submit_file(result_file)
  raise RuntimeError, "DOH!  Expected submission of result file '#{result_file} to fail, but it didn't!"
rescue Puppet::Error => e
  puts "Great success.  Result file '#{result_file}' is a #{File.size(result_file)}-byte repro case"
end


