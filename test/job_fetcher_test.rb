require_relative 'test_helper'

class JobFetcherTest < MiniTest::Test
  TEST_ITEM = 100000

  CLOCK = Time.now
  MONTH = CLOCK.strftime('%B')
  YEAR = CLOCK.year

  CLIENT = JobFetcher::ExconClient.new

  attr_reader :fetcher

  def setup
    @fetcher = JobFetcher.new(item, NullLogger.new)
  end

  def item
    TEST_ITEM
  end

  def stub_item(item, status, data)
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/#{item}.json").to_return({
      body: data,
      status: status
    })
  end

  def test_current_thread_finds_thread_based_on_time
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/user/whoshiring.json").to_return({
      body: JSON.dump({
        submitted: [ 3, 2, item ]
      }),
      status: 200
    })

    stub_item(item, 200, JSON.dump({
      title: "Who's hiring? (#{MONTH} #{YEAR})"
    }))

    stub_item(3, 200, JSON.dump({
      title: "Who's hiring? (Foo 0000)"
    }))

    stub_item(2, 200, JSON.dump({
      title: "Who's hiring? (Bar 0000)"
    }))

    assert_equal item, JobFetcher.find_thread(CLIENT, CLOCK)
  end

  def test_current_thread_returns_nil_if_no_active_thread
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/user/whoshiring.json").to_return({
      body: JSON.dump({
        submitted: [ 3, 2 ]
      }),
      status: 200
    })

    stub_item(3, 200, JSON.dump({
      title: "Who's hiring? (Foo 0000)"
    }))

    stub_item(2, 200, JSON.dump({
      title: "Who's hiring? (Bar 0000)"
    }))

    assert_nil JobFetcher.find_thread(CLIENT, CLOCK)
  end

  def test_current_thread_only_checks_first_three_submissions
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/user/whoshiring.json").to_return({
      body: JSON.dump({
        submitted: [ 3, 2, item, 4 ]
      }),
      status: 200
    })

    stub_item(item, 200, JSON.dump({
      title: "Who's hiring? (#{MONTH} #{YEAR})"
    }))

    stub_item(3, 200, JSON.dump({
      title: "Who's hiring? (Foo 0000)"
    }))

    stub_item(2, 200, JSON.dump({
      title: "Who's hiring? (Bar 0000)"
    }))

    ignored_item = stub_item(4, 200, JSON.dump({
      title: "Who's hiring? (Qux 0000)"
    }))

    JobFetcher.find_thread(CLIENT, CLOCK)

    assert_not_requested ignored_item
  end

  def test_parses_valid_data_into_jobs
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 200, JSON.dump({
      id: 'foo',
      time: CLOCK.to_i,
      text: 'placeholder'
    }))

    results = fetcher.get

    assert_equal 1, results.size
    job = results.first

    assert_equal 'foo', job.id
    assert_equal 'placeholder', job.text
    assert_equal CLOCK.to_i, job.timestamp.to_i
  end

  def test_skips_deleted_data
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 200, JSON.dump({
      deleted: true
    }))

    assert_empty fetcher.get
  end

  def test_skips_a_null_string_body
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 200, "null")

    assert_empty fetcher.get
  end

  def test_fails_if_first_api_requests_returns_non_200
    stub_item(item, 500, JSON.dump({
      kids: [ item.succ ]
    }))

    assert_raises Excon::Error::InternalServerError do
      fetcher.get
    end
  end

  def test_fails_if_child_api_requests_return_non_200
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 500, nil)

    assert_raises Excon::Error::InternalServerError do
      fetcher.get
    end
  end
end
