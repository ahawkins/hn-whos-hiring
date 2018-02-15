#!/usr/bin/env ruby

require 'bundler/setup'

require_relative '../src/app'

fetcher = JobFetcher.new('16282819')
fetcher.get.each do |job|
  puts job
end
