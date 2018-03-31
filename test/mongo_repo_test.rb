require_relative 'test_helper'

class MongoRepoTest < MiniTest::Test
  include DBTest

  CLOCK = Time.now

  def test_job_ads_are_sorted_by_timestamp
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

    results = repo.query_jobs

    assert_equal 2, results.size
    assert_equal job_2, results[0]
    assert_equal job_1, results[1]
  end

  def test_adding_job_ads_works_like_upsert
    job_1 = JobAd.new({
      id: 1,
      text: 'J1',
      timestamp: CLOCK
    })

    repo << job_1

    results = repo.query_jobs

    assert_equal 1, results.size
    assert_equal 'J1', results[0].text

    job_2 = JobAd.new({
      id: 1,
      text: 'J1-modified',
      timestamp: CLOCK
    })

    repo << job_2

    results = repo.query_jobs

    assert_equal 1, results.size
    assert_equal 'J1-modified', results[0].text
  end

  def test_freelance_ads_are_sorted_by_timestamp
    freelance_1 = FreelanceAd.new({
      id: 1,
      text: 'J1',
      timestamp: CLOCK - 1
    })

    freelance_2 = FreelanceAd.new({
      id: 2,
      text: 'J1',
      timestamp: CLOCK
    })

    repo << freelance_1 << freelance_2

    results = repo.query_freelancers

    assert_equal 2, results.size
    assert_equal freelance_2, results[0]
    assert_equal freelance_1, results[1]
  end

  def test_adding_freelance_ads_works_like_upsert
    freelance_1 = FreelanceAd.new({
      id: 1,
      text: 'J1',
      timestamp: CLOCK
    })

    repo << freelance_1

    results = repo.query_freelancers

    assert_equal 1, results.size
    assert_equal 'J1', results[0].text

    freelance_2 = FreelanceAd.new({
      id: 1,
      text: 'J1-modified',
      timestamp: CLOCK
    })

    repo << freelance_2

    results = repo.query_freelancers

    assert_equal 1, results.size
    assert_equal 'J1-modified', results[0].text
  end
end
