require 'htmlentities'

class JobAd
  class << self
    def from_hn(data)
      new({
        id: data.fetch('id'),
        timestamp: Time.at(data.fetch('time')),
        text: data.fetch('text')
      })
    end
  end

  attr_accessor :id, :text, :timestamp

  def initialize(id: nil, text: nil, timestamp: nil)
    @id = id
    @text = text
    @timestamp = timestamp
  end

  def ==(other)
    other.is_a?(self.class) && other.id == id
  end

  def remote?
    title? && title.match?(/REMOTE/)
  end

  def to_s
    text
  end

  def title?
    !title.nil?
  end

  def title
    paragraphs = text.split('<p>')

    # NOTE: The if check roughly matches something in the expected format:
    #
    # Company | Position | Title | [ REMOTE,ON-SITE | SALARY ]
    #
    # Properly formatted items should have at least the company, position,
    # title, and location. Salary and REMOTE/VISA tags are less likely, but
    # do occur. Checking for >= 3 bits of information approximates a well
    # formed submission.
    if paragraphs.size > 1 && paragraphs.first.count('|') >= 3
      sanitized = paragraphs.first.
        gsub(/<a[^>]+>.+<\/a>+/, "").
        strip

      decoded = HTMLEntities.new.decode(sanitized)

      if decoded.end_with?("|")
        decoded.chop.strip
      else
        decoded
      end
    else
      nil
    end
  end

  def link
    "https://news.ycombinator.com/item?id=#{id}"
  end
end
