#!/usr/bin/env ruby

require "json"

req_time_by_ver = {}
run_by_ver = {}

Dir["*.json"].each do |f|
  d = JSON.load File.read(f)
  rv = d["environment"]["RUBY_VERSION"]
  times = d["requests"]["times"].flat_map do |items|
    out_items = []
    cur_time = 0.0
    items.each do |i|
      out_items.push(i - cur_time)
      cur_time = i
    end
    out_items
  end
  req_time_by_ver[rv] ||= []
  req_time_by_ver[rv].concat times

  run_by_ver[rv] ||= []
  run_by_ver[rv].push d["requests"]["times"].map { |thread_times| thread_times[-1] }
end

def percentile(list, pct)
  len = list.length
  how_far = pct * 0.01 * (len - 1)
  prev_item = how_far.to_i
  return list[prev_item] if prev_item >= len - 1
  return list[0] if prev_item < 0

  linear_combination = how_far - prev_item
  list[prev_item] + (list[prev_item + 1] - list[prev_item]) * linear_combination
end

req_time_by_ver.keys.sort.each do |version|
  data = req_time_by_ver[version]
  data.sort!
  runs = run_by_ver[version]
  flat_runs = runs.flatten.sort

  print "=====\nRuby Version: #{version}, data points: #{data.size}, full runs: #{runs.size}\n"
  [0, 1, 5, 10, 50, 90, 95, 99, 100].each do |p|
    print "  #{"%2d" % p}%ile: #{percentile(data, p)}\n"
  end

  print "--\n  Overall thread completion times:\n"
  [0, 10, 50, 90, 100].each do |p|
    print "  #{"%2d" % p}%ile: #{percentile(flat_runs, p)}\n"
  end
end

print "******************\n"
