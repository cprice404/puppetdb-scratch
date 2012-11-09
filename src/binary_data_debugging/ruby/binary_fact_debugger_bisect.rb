#!/usr/bin/env ruby

require 'puppet'
require 'puppet/network/http_pool'

$LOAD_PATH << File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', '..', '..', 'puppetdb', 'puppet', 'lib')

require 'puppet/util/puppetdb'

Puppet.parse_config
Puppet[:certname] = "explosivo"
Puppet[:confdir] = "/home/cprice/work/puppet/puppet/test/client/conf"
Puppet[:vardir] = "/home/cprice/work/puppet/puppet/test/client/var"


class ThisIsStupid
  include Puppet::Util::Puppetdb

  BunkRequest = Struct.new(:server, :port, :key)

  # A `#submit_command` method that doesn't require an `Indirector::Request`
  #  argument.
  def submit_command(key, payload, command, version)
    bunk_request = BunkRequest.new("explosivo", 8081, key)
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
  last_failed_start = nil
  last_failed_end = nil
  while true
    begin
      puts "Trying #{start_offset}-#{end_offset}"
      submit_data(data, start_offset, end_offset)
      break [start_offset, end_offset, last_failed_start, last_failed_end]
    rescue Puppet::Error => e
      puts "Submission failed: '#{e}'"
      last_failed_start = start_offset
      last_failed_end = end_offset
      start_offset, end_offset = next_offsets_fn.call(start_offset, end_offset)
    end
  end
end

def find_smallest_failure(file)
  data = File.read(file)

  end_offset = 0
  last_failed_end = data.length
  start_offset = 0

  # this is pretty ugly and crappy, but it seems to work

  while ((end_offset - last_failed_end).abs > 1)
    puts "Narrowing range #{end_offset}-#{last_failed_end}"
    start_offset, end_offset, last_failed_start, last_failed_end =
        find_first_success(data, start_offset, last_failed_end, lambda { |x,y| [x, end_offset + ((y - end_offset) / 2)] } )

    puts "Working from end... success #{start_offset}-#{end_offset} (last failure: #{last_failed_start}-#{last_failed_end})"
  end

  if start_offset == 0 and end_offset == data.length
    raise RuntimeError, "This binary data passes the checksum, unable to find failure case."
  end

  puts "First successful substring working backwards from end: 0-#{end_offset}"

  # sentinel to get us into the loop
  start_offset = end_offset

  while ((start_offset - last_failed_start).abs > 1)
    puts "Narrowing range #{last_failed_start}-#{start_offset}"
    start_offset, end_offset, last_failed_start, last_failed_end =
        find_first_success(data, last_failed_start, end_offset + 1,
                           lambda { |x,y| [x + ((y - x) / 2), y] } )

    puts "Working from start... success #{start_offset}-#{end_offset} (last failure: #{last_failed_start}-#{last_failed_end})"
  end

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

unless ARGV[0]
  raise "Usage: binary_fact_debugger_bisect.rb <FILENAME>"
end

binary_file = ARGV[0]

unless File.exists?(binary_file)
  raise "Unable to locate specified file '#{binary_file}'"
end

#result_file = find_smallest_failure("../../data/binary_file_content/mytemplate.erb")
result_file = find_smallest_failure(binary_file)

puts "Double-checking result file ('#{result_file}'"
begin
  submit_file(result_file)
  raise RuntimeError, "DOH!  Expected submission of result file '#{result_file} to fail, but it didn't!"
rescue Puppet::Error => e
  puts "Great success.  Result file '#{File.expand_path(result_file)}' is a #{File.size(result_file)}-byte repro case."
  copied_file = File.join(File.dirname(File.expand_path(result_file)), "bad_binary_data.out")
  FileUtils.copy_file(File.expand_path(result_file), copied_file)
  puts "Copied file to '#{copied_file}'."

end


