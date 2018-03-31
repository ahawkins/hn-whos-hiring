ENV['RACK_ENV'] = 'test'

require 'bundler/setup'

require_relative '../src/app'

require 'logger/better'
require 'minitest/autorun'
require 'rack/test'
require 'capybara/dsl'
require 'webmock/minitest'

Capybara.app = WebServer

repo = MongoRepo.new(Mongo::Client.new(ENV.fetch('MONGODB_URI'), {
  logger: NullLogger.new
}))

WebServer.set(:repo, repo)

module DBTest
  def setup
    repo.clear
    repo.setup
  end

  def repo
    WebServer.settings.repo
  end
end

class AcceptanceTest < MiniTest::Test
  include DBTest
  include Capybara::DSL

  CLOCK = Time.now

  def open_jobs
    visit '/'
    assert_equal 'Jobs', find('.navbar .active a').text
  end

  def open_freelancers
    visit '/freelancers'
    assert_equal 'Freelancers', find('.navbar .active a').text
  end

  def select_all_posts
    select('All', from: 'post-filter')
    click_button('get-posts')
  end

  def search_for(query)
    fill_in('keyword', with: query)
    click_button('get-posts')
  end

  def assert_results(total)
    assert_equal total, page.all('li.post').size
  end

  def assert_post(id)
    find("a#post-#{id}").tap do |link|
      yield link if block_given?
    end
  end

  def assert_keyword(query)
    assert_equal query, find('#keyword').value
  end
end

class RSSTest < MiniTest::Test
  include Rack::Test::Methods
  include DBTest

  CLOCK = Time.now

  def app
    WebServer
  end

  def get_rss(path, params = { })
    get(path, params) do |response|
      assert last_response.ok?, "GET /#{path} failed"
      assert_equal 'application/rss+xml;charset=utf-8', last_response['Content-Type']
    end

    feed = RSS::Parser.parse(last_response.body).tap do |feed|
      yield feed, feed.items if block_given?
    end

    feed.items
  end

  def assert_feed_item(job, item)
    assert_equal job.link, item.link
    assert_equal job.text, item.description
    assert_equal job.id.to_s, item.guid.content

    yield item if block_given?
  end
end
