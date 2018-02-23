require_relative 'test_helper'

class HiringParserTest < MiniTest::Test
  def parse(id: 1, text: 'Company | Position | Location | Tags | Salary', timestamp: Time.now)
    JobAd.from_hn({
      'id' => id,
      'text' => text,
      'time' => Time.now
    })
  end

  def test_parsing_scenarios
    [
      [
        %{Company | Title | Location | $100k<p>Bar},
        { title: 'Company | Title | Location | $100k', remote: false }
      ],
      [
        # Remote in title
        %{Company | Title | REMOTE | $100k<p>Bar},
        { title: 'Company | Title | REMOTE | $100k', remote: true }
      ],
      [
        # Remote outside title
        %{Company | Title | $100k<p>Bar, REMOTE},
        { title: 'Company | Title | $100k', remote: true }
      ],
      [
        # Splits title by \n as well
        %{Company | Title | REMOTE | $100k\nBar},
        { title: 'Company | Title | REMOTE | $100k' }
      ],
      [
        # Skips texts without properly formatted first line
        %{Malformed long lorem ipsum post without paragraphs},
        { title: nil, remote: false }
      ],
      [
        # Decodes HTML Entities
        %{The Farmer&#x27;s Dog | Title | Location | $100k\nMore},
        { title: "The Farmer's Dog | Title | Location | $100k", remote: false }
      ]
    ].each do |(text, output)|
      job = parse({
        text: text
      })

      assert_equal HTMLEntities.new.decode(text), job.to_s, "#{text} parse failure"

      if output.key?(:remote)
        assert job.remote? == output.fetch(:remote), "#{text} parse failure"
      end

      if output.fetch(:title).nil?
        refute job.title?, "#{text} set title"
        assert_nil job.title, "#{text} set title"
      else
        assert job.title?, "#{text} title parse failure"
        assert_equal output.fetch(:title), job.title, "#{text} title parse failure"
      end
    end
  end
end
