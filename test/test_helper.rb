ENV['RACK_ENV'] = 'test'

require 'bundler/setup'

require_relative '../src/app'

require 'logger/better'
require 'minitest/autorun'
require 'rack/test'
require 'capybara/dsl'

Capybara.app = WebServer

logger = NullLogger.new.tap do |log|
  log.level = :debug
end

repo = MongoRepo.new(Mongo::Client.new(ENV.fetch('MONGODB_URI'), {
  logger: logger
}))

WebServer.set(:repo, repo)

module DBTest
  def setup
    repo.setup
  end

  def repo
    WebServer.settings.repo
  end

  def teardown
    repo.clear
  end
end
