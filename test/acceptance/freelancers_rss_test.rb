require_relative '../test_helper'

class FreelancersRSSTest < RSSTest
  def test_titles_are_truncated
    ad = FreelanceAd.new({
      id: 1,
      text: 'Lorem Ipsum' * 100,
      timestamp: CLOCK + 2
    })

    repo << ad

    get_rss '/rss/freelancers' do |feed, items|
      assert_equal 1, items.size
      assert_feed_item ad, items[0] do |item|
        assert item.title.end_with?('...')
      end
    end
  end

  def test_filters
    seeking_work = FreelanceAd.new({
      id: 1,
      text: 'SEEKING WORK',
      timestamp: CLOCK
    })

    seeking_freelancer = FreelanceAd.new({
      id: 2,
      text: 'SEEKING FREELANCER',
      timestamp: CLOCK + 1
    })

    remote_ad = FreelanceAd.new({
      id: 3,
      text: 'SEEKING WORK | REMOTE',
      timestamp: CLOCK + 2
    })

    repo << seeking_work << seeking_freelancer << remote_ad

    get_rss '/rss/freelancers' do |feed, items|
      assert_equal 3, items.size
      assert_feed_item remote_ad, items[0]
      assert_feed_item seeking_freelancer, items[1]
      assert_feed_item seeking_work, items[2]
    end

    get_rss '/rss/freelancers', filter: :seeking_work do |feed, items|
      assert_equal 2, items.size
      assert_feed_item remote_ad, items[0]
      assert_feed_item seeking_work, items[1]
    end

    get_rss '/rss/freelancers', filter: :seeking_work, remote: :true do |feed, items|
      assert_equal 1, items.size
      assert_feed_item remote_ad, items[0]
    end
  end
end
