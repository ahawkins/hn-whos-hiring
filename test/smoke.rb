require 'bundler/setup'
require 'minitest/autorun'
require 'excon'

class SmokeTest < MiniTest::Test
  attr_reader :host

  def setup
    @host = ARGV[0]
  end

  def test_root_path_returns_200
    response = Excon.get(host)
    assert_equal 200, response.status
  end

  def test_rss_path_returns_200
    response = Excon.get("#{host}/rss")
    assert_equal 200, response.status
  end

  def test_freelance_path_returns_200
    response = Excon.get("#{host}/freelancers")
    assert_equal 200, response.status
  end

  def test_freelance_rss_path_returns_200
    response = Excon.get("#{host}/rss/freelancers")
    assert_equal 200, response.status
  end
end
