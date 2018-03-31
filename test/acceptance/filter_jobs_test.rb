require_relative '../test_helper'

class FilterJobsTest < AcceptanceTest
  def test_display_of_welformed_job
    repo << JobAd.new({
      id: 1,
      text: 'Company | Position | Location | Salary<p>More',
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Company | Position | Location | Salary', link.text
    end
  end

  def test_display_of_job_without_title
    repo << JobAd.new({
      id: 1,
      text: 'Foo | Bar',
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Foo | Bar', link.text
    end
  end

  def test_long_malformed_jobs_are_truncated
    repo << JobAd.new({
      id: 1,
      text: 'Lorem Ipsum' * 500,
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert link.text.end_with?('...'), 'No truncation'
    end
  end

  def test_long_titles_are_truncated
    repo << JobAd.new({
      id: 1,
      text: ('Lorem Ipsum' * 500) + "\nMore",
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert link.text.end_with?('...'), 'No truncation'
    end
  end

  def test_links_are_stripped_from_titles
    repo << JobAd.new({
      id: 1,
      text: 'Company | Position | Location | Salary | <a href="#">Foo</a><p>More',
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Company | Position | Location | Salary', link.text
    end
  end

  def test_links_are_stripped_from_titleless_jobs
    repo << JobAd.new({
      id: 1,
      text: 'Company | Position | Location | Salary | <a href="#">Foo</a>',
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Company | Position | Location | Salary', link.text
    end
  end

  def test_links_are_stripped_from_jobs_with_titles
    repo << JobAd.new({
      id: 1,
      text: %Q{Company | Position | Location | Salary | <a href="#">Foo</a>\nMore},
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Company | Position | Location | Salary', link.text
    end
  end

  def test_paren_wrapped_links_are_stripped_from_jobs_without_titles
    repo << JobAd.new({
      id: 1,
      text: 'Company | Position | Location | Salary | (<a href="#">Foo</a>)',
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Company | Position | Location | Salary', link.text
    end
  end

  def test_paren_wrapped_links_are_stripped_from_jobs_with_titles
    repo << JobAd.new({
      id: 1,
      text: %Q{Company | Position | Location | Salary | (<a href="#">Foo</a>)\nMore},
      timestamp: CLOCK
    })

    open_jobs

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Company | Position | Location | Salary', link.text
    end
  end

  def test_keyword
    repo << JobAd.new({
      id: 1,
      text: 'Job_A | ONSITE | $60k',
      timestamp: CLOCK
    })

    repo << JobAd.new({
      id: 2,
      text: 'Job_B | REMOTE | $100k',
      timestamp: CLOCK
    })

    open_jobs

    assert_results 2

    search_for 'Job_B'
    assert_keyword 'Job_B'

    assert_results 1
    assert_post 2
  end

  def test_remote_job_filter
    repo << JobAd.new({
      id: 1,
      text: 'Foo | Bar | ONSITE | $60k',
      timestamp: CLOCK
    })

    repo << JobAd.new({
      id: 2,
      text: 'Foo | Bar | REMOTE | $100k<p>More',
      timestamp: CLOCK
    })

    open_jobs

    assert_results 2
    assert_all_jobs_selected

    select_remote

    assert_results 1
    assert_post 2
    assert_remote_selected
    refute_all_jobs_selected

    select_all_posts

    assert_results 2
    assert_all_jobs_selected
    refute_remote_selected
  end

  private

  def select_remote
    select('Remote', from: 'post-filter')
    click_button('get-posts')
  end

  def assert_all_jobs_selected
    assert has_select?('post-filter', selected: 'All'), 'All filter incorrect'
  end

  def refute_all_jobs_selected
    refute has_select?('post-filter', selected: 'All'), 'All filter incorrect'
  end

  def assert_remote_selected
    assert has_select?('post-filter', selected: 'Remote'), 'Remote filter incorrect'
  end

  def refute_remote_selected
    refute has_select?('post-filter', selected: 'Remote'), 'Remote filter incorrect'
  end
end
