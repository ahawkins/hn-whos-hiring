require_relative 'test_helper'

class ItemFetcherTest < MiniTest::Test
  TEST_ITEM = 100000

  attr_reader :fetcher

  def setup
    @fetcher = ItemFetcher.new
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

  def test_parses_valid_data_into_jobs
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 200, JSON.dump({
      id: 'foo',
    }))

    results = fetcher.get item do |data|
      data
    end

    assert_equal 1, results.size
    assert_equal({ 'id' => 'foo' }, results[0])
  end

  def test_skips_deleted_data
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 200, JSON.dump({
      deleted: true
    }))

    assert_empty fetcher.get(item)
  end

  def test_skips_a_null_string_body
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 200, "null")

    assert_empty fetcher.get(item)
  end

  def test_fails_if_first_api_requests_returns_non_200
    stub_item(item, 500, JSON.dump({
      kids: [ item.succ ]
    }))

    assert_raises APIError do
      fetcher.get(item)
    end
  end

  def test_fails_if_child_api_requests_return_non_200
    stub_item(item, 200, JSON.dump({
      kids: [ item.succ ]
    }))

    stub_item(item.succ, 500, nil)

    assert_raises APIError do
      fetcher.get(item)
    end
  end
end
