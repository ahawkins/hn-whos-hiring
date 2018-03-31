require_relative 'test_helper'

class ThreadFinderTest < MiniTest::Test
  def stub_items(ids)
		stub_request(:get, "https://hacker-news.firebaseio.com/v0/user/whoishiring.json").to_return({
      body: JSON.dump({
        submitted: ids
      }),
      status: 200
    })
  end

	def stub_item(item, data)
    stub_request(:get, "https://hacker-news.firebaseio.com/v0/item/#{item}.json").to_return({
      body: JSON.dump(data),
      status: 200
    })
  end

  def locate(&block)
    ThreadFinder.new.locate(&block)
  end

  def test_finds_items_against_the_block
    stub_items([1, 2])

    stub_item(1, { title: 'Foo' })
    stub_item(2, { title: 'Bar' })

    match = locate do |item|
      item.fetch('title') == 'Foo'
    end

    assert_equal match, 1
  end

  def test_only_checks_the_first_three_items
    stub_items([ 1, 2, 3, 4 ])

    stub_item(1, { title: 'Placeholder' })
    stub_item(2, { title: 'Placeholder' })
    stub_item(3, { title: 'Placeholder' })
    skipped = stub_item(4, { title: 'Placeholder' })

    locate { true }

    assert_not_requested skipped
  end
end
