#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'set'

unless ARGV.count > 1
  puts "Usage: json_diff.rb json_file_1.json json_file_2.json"
  exit
end

def different?(a, b, bi_directional=true)
  return [a.class.name, nil] if !a.nil? && b.nil?
  return [nil, b.class.name] if !b.nil? && a.nil?

  differences = {}
  a.each do |k, v|
    if !v.nil? && b[k].nil?
      differences[k] = [v, nil]
      next
    elsif !b[k].nil? && v.nil?
      differences[k] = [nil, b[k]]
      next
    end

    if v.is_a?(Hash)
      unless b[k].is_a?(Hash)
        differences[k] = "Different types"
        next
      end
      diff = different?(a[k], b[k])
      differences[k] = diff if !diff.nil? && diff.count > 0

    elsif v.is_a?(Array)
      unless b[k].is_a?(Array)
        differences[k] = "Different types"
        next
      end

      #c = 0
      #diff = v.map do |n|
      #  if n.is_a?(Hash)
      #    diffs = different?(n, b[k][c])
      #    c += 1
      #    ["Differences: ", diffs] unless diffs.nil?
      #  else
      #    c += 1
      #    [n , b[c]] unless b[c] == n
      #  end
      #end.compact

      left = Set.new(v)
      right = Set.new(b[k])
      unless left == right
        differences[k] = [(left - right).to_a, (right -left).to_a]
      end

      #differences[k] = diff if diff.count > 0

    else
      differences[k] = [v, b[k]] unless v == b[k]

    end
  end

  return differences if !differences.nil? && differences.count > 0
end

json_a = JSON.parse(File.read(ARGV[0]))
json_b = JSON.parse(File.read(ARGV[1]))

differences = different?(json_a, json_b)

if ARGV[2]
  File.open(ARGV[2], 'w'){ |f| f.write(JSON.pretty_generate(differences)) }
else
  puts JSON.pretty_generate(differences)
end