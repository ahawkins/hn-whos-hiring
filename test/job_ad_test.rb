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
      [ %{Company | Title | Location | $100k<p>Bar},
        { title: 'Company | Title | Location | $100k', remote: false }
      ],
      [ %{Company | Title | REMOTE | $100k<p>Bar},
        { title: 'Company | Title | REMOTE | $100k', remote: true }
      ],
      [
        # Skips texts without properly formatted first line
        %{Malformed long lorem ipsum post without paragraphs},
        { title: nil, remote: false }
      ],
      [
        # Strips links
        %{Foo | Bar | Baz | <a href="https:&#x2F;&#x2F;alloy.ai" rel="nofollow">https:&#x2F;&#x2F;alloy.ai</a><p>Description},
        { title: 'Foo | Bar | Baz', remote: false }
      ],
      [
        # Decodes HTML Entities in title
        %{The Farmer&#x27;s Dog | Title | Location | $100k<p>Description},
        { title: "The Farmer's Dog | Title | Location | $100k", remote: false }
      ],
      [
        # Skips title for entires without proper header in first paragraph
        %{Some random text<p>followed by more random text},
        { title: nil, remote: false }
      ]
    ].each do |(text, output)|
      job = parse({
        text: text
      })

      assert_equal text, job.to_s, "#{text} parse failure"
      assert job.remote? == output.fetch(:remote), "#{text} parse failure"

      if output.fetch(:title)
        assert job.title?, "#{text} to title parse failure"
        assert_equal output.fetch(:title), job.title, "#{text} to title parse failure"
      else
        refute job.title?, "#{text} to title parse failure"
        assert_nil job.title, "#{text} to title parse failure"
      end
    end
  end
end
