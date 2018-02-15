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
end
