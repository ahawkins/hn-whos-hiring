require_relative './test_helper'

class HTTPCachingTest < MiniTest::Test
  include Rack::Test::Methods

  attr_reader :app

  def setup
    WebServer.set(:repo, FakeRepo.new)

    @app = WebServer
  end

  def test_index_is_cached_when_configured
    app.set(:expire, 1000)

    get('/')

    assert_includes(last_response['Cache-Control'], 'public')
    assert_includes(last_response['Cache-Control'], "max-age=#{app.settings.expire}")
  end

  def test_is_not_cached_when_not_configured
    app.set(:expire, nil)

    get '/'

    refute last_response['Cache-Control']
  end
end
