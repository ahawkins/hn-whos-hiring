require_relative 'test_helper'

class AcceptanceTest < MiniTest::Test
  include Capybara::DSL
  include DBTest

  CLOCK = Time.now

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

  def test_remote_only_job_filter
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
		assert_all_jobs_selected

    click_remote_only

    assert_results 1
    assert_job_id 2
		assert_remote_only_selected
		refute_all_jobs_selected

    click_all_jobs

    assert_results 2
		assert_all_jobs_selected
		refute_remote_only_selected
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

  def click_remote_only
    find('#remote-only').click
  end

  def click_all_jobs
    find('#all-jobs').click
  end

	def assert_all_jobs_selected
		assert page.has_css?('#all-jobs.is-active'), 'Incorrect filter display'
	end

	def refute_all_jobs_selected
		refute page.has_css?('#all-jobs.is-active'), 'Incorrect filter display'
	end

	def assert_remote_only_selected
		assert page.has_css?('#remote-only.is-active'), 'Incorrect filter display'
	end

	def refute_remote_only_selected
		refute page.has_css?('#remote-only.is-active'), 'Incorrect filter display'
	end
end
