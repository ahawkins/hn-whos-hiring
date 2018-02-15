require_relative 'test_helper'

class HiringParserTest < MiniTest::Test
  def parse(id: 1, text: 'Company | Position | Location | Tags | Salary', timestamp: Time.now)
    JobAd.from_hn({
      'id' => id,
      'text' => text,
      'time' => Time.now
    })
  end

  def test_remote_flag_parsing
    [
      [ %Q{Uncountable | Machine Learning Engineers | San Francisco (Onsite) | $150k-220k & Enterprise Sales | San Francisco (Onsite) | $70-120k + Commission}, false ],
      [ %{Shogun (YC W18) | Mid-Senior Full Stack Engineer | REMOTE, ON SITE (SF) | https://getshogun.com | $100-$140k + generous equity}, true ]
    ].each do |(text, result)|
      job = parse({
        text: text
      })

      assert job.remote? == result, "#{text} parsed incorrectly"
    end
  end

  def test_lops_off_trailing_pipe
    job = parse({
      text: 'Company | Position | Location | Tags | Salary |<p>Junk'
    })

    assert_equal 'Company | Position | Location | Tags | Salary', job.text

    job = parse({
      text: 'Company | Position | Location | Tags | Salary |'
    })

    assert_equal 'Company | Position | Location | Tags | Salary', job.text
  end

  def test_lops_off_extra_paragraphs
    job = parse({
      text: 'Company | Position | Location | Tags | Salary<p>Junk'
    })

    assert_equal 'Company | Position | Location | Tags | Salary', job.text
  end

  def test_strips_links_from_text
    job = parse({
      text: %Q{foo <a href="https:&#x2F;&#x2F;alloy.ai" rel="nofollow">https:&#x2F;&#x2F;alloy.ai</a>}
    })

    assert_equal 'foo', job.to_s
  end

  def test_converts_html_entities
    job = parse({
      text: 'The Farmer&#x27;s Dog'
    })

    assert_equal %Q{The Farmer's Dog}, job.to_s
  end
end
