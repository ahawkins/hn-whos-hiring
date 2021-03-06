require_relative '../test_helper'

class JobAdRSSTest < RSSTest
  def test_title_of_welformed_job
    job = JobAd.new({
      id: 1,
      text: 'Company | Position | Location | $100k<p>More',
      timestamp: CLOCK
    })

    repo << job

    get_rss '/rss' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item job, items[0] do |item|
        assert_equal job.title, item.title
      end
    end
  end

  def test_title_of_malformed_job
    job = JobAd.new({
      id: 1,
      text: 'Foo | Bar',
      timestamp: CLOCK
    })

    repo << job

    get_rss '/rss' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item job, items[0] do |item|
        assert_equal job.text, item.title
      end
    end
  end

  def test_long_malformed_text_postings_become_truncated_titles
    job = JobAd.new({
      id: 1,
      text: 'Lorem Ipsum' * 100,
      timestamp: CLOCK
    })

    repo << job

    get_rss '/rss' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item job, items[0] do |item|
        assert item.title.end_with?('...'), 'No truncation'
      end
    end
  end

  def test_links_are_stripped_from_titles
    job = JobAd.new({
      id: 1,
      text: 'Company | Position | Location | Salary | <a href="#">Foo</a><p>More',
      timestamp: CLOCK
    })

    repo << job

    get_rss '/rss' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item job, items[0] do |item|
        assert_equal 'Company | Position | Location | Salary', item.title
      end
    end
  end

  def test_links_are_stripped_from_titlesless_job_ads
    job = JobAd.new({
      id: 1,
      text: 'Company | Position | Location | Salary | <a href="#">Foo</a>',
      timestamp: CLOCK
    })

    repo << job

    get_rss '/rss' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item job, items[0] do |item|
        assert_equal 'Company | Position | Location | Salary', item.title
      end
    end
  end

  def test_empty_pipes_stripped_from_titlesless_job_ads
    job = JobAd.new({
      id: 1,
      text: 'Company | Position | Location | <a href="#">Foo</a> | Salary',
      timestamp: CLOCK
    })

    repo << job

    get_rss '/rss' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item job, items[0] do |item|
        assert_equal 'Company | Position | Location | Salary', item.title
      end
    end
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

    get_rss '/rss' do |feed, items|
      assert_equal 2, items.size
      assert_feed_item remote_job, items[0]
      assert_feed_item job, items[1]
    end

    get_rss '/rss', filter: :remote do |feed, items|
      assert_equal 1, items.size
      assert_feed_item remote_job, items[0]
    end
  end

  def test_keyword
    job_a = JobAd.new({
      id: 1,
      text: 'Foo',
      timestamp: CLOCK
    })

    job_b = JobAd.new({
      id: 2,
      text: 'Bar',
      timestamp: CLOCK + 1
    })

    repo << job_a << job_b

    get_rss '/rss', q: 'Bar' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item job_b, items[0]
    end
  end
end
