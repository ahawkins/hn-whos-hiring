require 'htmlentities'

class JobAd
  class << self
    def from_hn(data)
      new.tap do |job|
        job.id = data.fetch('id')
        job.timestamp = Time.at(data.fetch('time'))

        sanatized = data.fetch('text').
          split('<p>').
          first.
          gsub(/<a[^>]+>.+<\/a>+/, "").
          strip

        decoded = HTMLEntities.new.decode(sanatized)

        if decoded.end_with?("|")
          job.text = decoded.chop.strip
        else
          job.text = decoded
        end
      end
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
    to_s.match?(/REMOTE/)
  end

  def to_s
    text
  end

  def link
    "https://news.ycombinator.com/item?id=#{id}"
  end
end

