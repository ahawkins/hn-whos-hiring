$stdout.sync = true
$stderr.sync = true

require 'bundler/setup'

require 'logger/better'

require 'parallel'
require 'excon'

require_relative 'mongo_repo'
require_relative 'web_server'

require_relative 'job_ad'
require_relative 'freelance_ad'

require_relative 'json_client'
require_relative 'thread_finder'
require_relative 'item_fetcher'

require_relative 'web_server'
