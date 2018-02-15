require_relative 'test_helper'

class RSSTest < MiniTest::Test
  include Rack::Test::Methods
  include DBTest

  CLOCK = Time.now

  def app
    WebServer
  end

  def test_simple_case
    job = JobAd.new({
      id: 1,
      text: 'Foo | Bar',
      timestamp: CLOCK
    })

    repo << job

    items = get_rss do |feed, items|
      assert_equal 1, feed.items.size
    end

    assert_feed_item job, items[0]
  end

  def test_filters
    job = JobAd.new({
      id: 1,
      text: 'Foo | Bar',
      timestamp: CLOCK
    })

    remote_job = JobAd.new({
      id: 2,
      text: 'Foo | Bar | REMOTE',
      timestamp: CLOCK + 1
    })

    repo << job << remote_job

    items = get_rss

    assert_feed_item remote_job, items[0]
    assert_feed_item job, items[1]

    get_rss remote: true do |feed, items|
      assert_equal 1, feed.items.size
    end

    assert_feed_item remote_job, items[0]
  end

  def get_rss(params = { })
    get('/rss', params) do |response|
      assert last_response.ok?
      assert_equal 'application/rss+xml', last_response['Content-Type']
    end

    feed = RSS::Parser.parse(last_response.body) do |feed|
      yield feed, feed.items if block_given?
    end

    feed.items
  end

  def assert_feed_item(job, item)
    assert_equal job.to_s, item.title
    assert_equal job.link, item.link
    assert_equal job.id.to_s, item.guid.content
  end
end
