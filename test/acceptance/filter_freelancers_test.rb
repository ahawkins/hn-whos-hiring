require_relative '../test_helper'

class FilterFreelanceAdsTest < AcceptanceTest
  def test_display_of_short_title
    repo << FreelanceAd.new({
      id: 1,
      text: 'Placeholder',
      timestamp: CLOCK
    })

    open_freelancers

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Placeholder', link.text
    end
  end

  def test_long_posts_are_truncated
    repo << FreelanceAd.new({
      id: 1,
      text: 'Lorem Ipsum' * 500,
      timestamp: CLOCK
    })

    open_freelancers

    assert_results 1

    assert_post 1 do |link|
      assert link.text.end_with?('...'), 'No truncation'
    end
  end

  def test_links_are_stripped_from_titles
    repo << FreelanceAd.new({
      id: 1,
      text: 'Foo <a href="#">bar</a>',
      timestamp: CLOCK
    })

    open_freelancers

    assert_results 1

    assert_post 1 do |link|
      assert_equal 'Foo', link.text
    end
  end

  def test_keyword
    repo << FreelanceAd.new({
      id: 1,
      text: 'Placeholder Job_A',
      timestamp: CLOCK
    })

    repo << FreelanceAd.new({
      id: 2,
      text: 'Placeholder Job_B',
      timestamp: CLOCK
    })

    open_freelancers

    assert_results 2

    search_for 'Job_B'
    assert_keyword 'Job_B'

    assert_results 1
    assert_post 2
  end

  def test_seeking_work_seeking_freelancer_filter
    repo << FreelanceAd.new({
      id: 1,
      text: 'SEEKING WORK - Foo',
      timestamp: CLOCK
    })

    repo << FreelanceAd.new({
      id: 2,
      text: 'SEEKING FREELANCER - Bar',
      timestamp: CLOCK
    })

    open_freelancers

    assert_results 2
    assert_all_posts_selected

    select_seeking_work

    assert_results 1
    assert_post 1
    assert_seeking_work_selected
    refute_seeking_freelancer_selected

    select_seeking_freelancer

    assert_results 1
    assert_post 2
    assert_seeking_freelancer_selected
    refute_seeking_work_selected
  end

  def test_remote_combines_with_main_filter
    repo << FreelanceAd.new({
      id: 1,
      text: 'SEEKING WORK - Foo',
      timestamp: CLOCK
    })

    repo << FreelanceAd.new({
      id: 2,
      text: 'SEEKING FREELANCER - Bar',
      timestamp: CLOCK
    })

    repo << FreelanceAd.new({
      id: 3,
      text: 'SEEKING WORK - REMOTE, Baz',
      timestamp: CLOCK
    })

    open_freelancers

    assert_results 3

    select_seeking_work

    assert_results 2
    assert_post 1
    assert_post 3
    assert_seeking_work_selected

    check_remote

    assert_results 1
    assert_post 3
    assert_seeking_work_selected
    assert_remote_checked
  end

  private

  def select_seeking_work
    select('Seeking Work', from: 'post-filter')
    click_button('get-posts')
  end

  def select_seeking_freelancer
    select('Seeking Freelancer', from: 'post-filter')
    click_button('get-posts')
  end

  def check_remote
    check('Remote?')
    click_button('get-posts')
  end

  def assert_all_posts_selected
    assert has_select?('post-filter', selected: 'All'), 'Filter incorrect'
  end

  def assert_seeking_work_selected
    assert has_select?('post-filter', selected: 'Seeking Work'), 'Filter incorrect'
  end

  def refute_seeking_work_selected
    refute has_select?('post-filter', selected: 'Seeking Work'), 'Filter incorrect'
  end

  def refute_seeking_freelancer_selected
    refute has_select?('post-filter', selected: 'Seeking Freelancer'), 'Filter incorrect'
  end

  def assert_seeking_freelancer_selected
    assert has_select?('post-filter', selected: 'Seeking Freelancer'), 'Filter incorrect'
  end

  def assert_remote_checked
    assert has_checked_field?('remote'), 'Remote not checked'
  end
end
