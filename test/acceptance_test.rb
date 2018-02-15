require_relative 'test_helper'

class AcceptanceTest < MiniTest::Test
  include Capybara::DSL

  CLOCK = Time.now

  def setup
    super

    WebServer.set(:repo, FakeRepo.new)
  end

  def repo
    WebServer.settings.repo
  end

  def test_simple_case
    repo << JobAd.new({
      id: 1,
      text: 'Foo | Bar',
      timestamp: CLOCK
    })

    visit '/'

    assert_results 1

    assert_job_id 1 do |link|
      assert_equal 'Foo | Bar', link.text
    end
  end

  def test_remote_job_filter
    repo << JobAd.new({
      id: 1,
      text: 'Foo | Bar',
      timestamp: CLOCK
    })

    repo << JobAd.new({
      id: 2,
      text: 'Foo | Bar | REMOTE',
      timestamp: CLOCK
    })

    open_homepage

    assert_results 2

    click_remote

    assert_results 1

    assert_job_id 2
  end

  private

  def open_homepage
    visit '/'
  end

  def assert_results(total)
    assert_equal total, page.all('li.job').size
  end

  def assert_job_id(id)
    find("a#job-#{id}").tap do |link|
      yield link if block_given?
    end
  end

  def click_remote
    find('#remote-only').click
  end
end
