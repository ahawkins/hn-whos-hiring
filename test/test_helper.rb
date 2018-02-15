ENV['RACK_ENV'] = 'test'

require 'bundler/setup'

require_relative '../src/app'
require_relative '../src/fakes'

require 'minitest/autorun'
require 'rack/test'
require 'capybara/dsl'

Capybara.app = WebServer
