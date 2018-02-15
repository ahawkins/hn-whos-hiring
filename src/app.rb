$stdout.sync = true
$stderr.sync = true

require 'bundler/setup'

require_relative 'mongo_repo'
require_relative 'web_server'
require_relative 'job_ad'
require_relative 'job_fetcher'
