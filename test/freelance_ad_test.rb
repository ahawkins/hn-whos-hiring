require_relative 'test_helper'

class FreelandAdTest < MiniTest::Test
  def parse(id: 1, text:, timestamp: Time.now)
    FreelanceAd.from_hn({
      'id' => id,
      'text' => text,
      'time' => Time.now
    })
  end

  def test_title
    run_test_samples([
      # Stripping junk after keyword
      [
        %{SEEKING WORK - San Francisco, Ruby},
        { title: 'San Francisco, Ruby' }
      ],
      # Stripping junk before keyword
      [
        %{--- SEEKING WORK --- San Francisco, Ruby},
        { title: 'San Francisco, Ruby' }
      ],
      # Stripping junk that results in extra p
      [
        %{---<p>SEEKING WORK --- San Francisco, Ruby},
        { title: 'San Francisco, Ruby' }
      ],
      [
        %{<p>SEEKING WORK --- San Francisco, Ruby},
        { title: 'San Francisco, Ruby' }
      ],
      # joins by <p>
      [
        %{Foo<p>Bar},
        { title: 'Foo; Bar' }
      ]
    ])
  end

  def test_remote_flag
    run_test_samples([
      [
        %{Placeholder | REMOTE},
        { remote: true }
      ],
      [
        %{Placeholder | Remote: OK},
        { remote: true }
      ],
      [
        %{Placeholder | Remote: Ok},
        { remote: true }
      ],
      [
        %{Placeholder | REMOTE: OK},
        {  remote: true }
      ],
      [
        %{Placeholder | Remote: Yes},
        { remote: true }
      ],
      [
        %{Placeholder | Remote: YES},
        { remote: true }
      ],
      [
        %{Placeholder | REMOTE: YES},
        { remote: true }
      ],
      [
        %{Placeholder | Remote only},
        { remote: true }
      ]
    ])
  end

  def test_seeking_work_flag
    run_test_samples([
      [
        %{SEEKING WORK},
        { seeking_work: true }
      ],
      [
        %{SEEKING FREELANCER},
        { seeking_work: false }
      ],
      [
        %{SEEKING FREELANCERS},
        { seeking_work: false }
      ],
      # Scenarios without appropriate key words
      [
        %{No keywords},
        { seeking_work: true }
      ]
    ])
  end

  def run_test_samples(items)
    items.each do |(text, output)|
      job = parse({
        text: text
      })

      assert_equal HTMLEntities.new.decode(text), job.to_s, "#{text} parse failure"

      if output.key?(:remote)
        assert job.remote? == output.fetch(:remote), "#{text} failed to parse remote flag"
      end

      if output.key?(:seeking_work)
        assert job.seeking_work? == output.fetch(:seeking_work), "#{text} failed to parse seeking work"
      end

      if output.key?(:title)
        assert_equal output.fetch(:title),  job.title, "#{text} title error"
      end
    end
  end
end
