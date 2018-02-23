require_relative 'test_helper'

class MongoRepoTest < MiniTest::Test
  include DBTest

  CLOCK = Time.now

  def test_items_are_kept_in_sorted_order
    job_1 = JobAd.new({
      id: 1,
      text: 'J1',
      timestamp: CLOCK - 1
    })

    job_2 = JobAd.new({
      id: 2,
      text: 'J1',
      timestamp: CLOCK
    })

    repo << job_1 << job_2

    results = repo.query

    assert_equal 2, results.size
    assert_equal job_2, results[0]
    assert_equal job_1, results[1]
  end

  def test_query_with_remote_flag
    job_1 = JobAd.new({
      id: 1,
      text: 'J1',
      timestamp: CLOCK - 1
    })
    refute job_1.remote?

    job_2 = JobAd.new({
      id: 2,
      text: 'J1 | REMOTE',
      timestamp: CLOCK
    })
    assert job_2.remote?

    repo << job_1 << job_2

    results = repo.query({ remote_only: false })

    assert_equal 2, results.size
    assert_equal job_2, results[0]
    assert_equal job_1, results[1]

    results = repo.query({ remote_only: true })

    assert_equal 1, results.size
    assert_equal job_2, results[0]
  end

  def test_pushing_works_like_upsert
    job_1 = JobAd.new({
      id: 1,
      text: 'J1',
      timestamp: CLOCK
    })

    repo << job_1

    results = repo.query

    assert_equal 1, results.size
    assert_equal 'J1', results[0].text

    job_2 = JobAd.new({
      id: 1,
      text: 'J1-modified',
      timestamp: CLOCK
    })

    repo << job_2

    results = repo.query

    assert_equal 1, results.size
    assert_equal 'J1-modified', results[0].text
  end
end
