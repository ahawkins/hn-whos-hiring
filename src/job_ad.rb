require 'htmlentities'

class JobAd
  class << self
    def from_hn(data)
      new({
        id: data.fetch('id'),
        timestamp: Time.at(data.fetch('time')),
        text: HTMLEntities.new.decode(data.fetch('text'))
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
    text.match?(/REMOTE/)
  end

  def to_s
    text
  end

  def title?
    !title.nil?
  end

  def title
    paragraphs = text.split(/($|<p>)/)
    if paragraphs.size > 1
      paragraphs.first
    else
      nil
    end
  end

  def link
    "https://news.ycombinator.com/item?id=#{id}"
  end
end
