$stdout.sync = true
$stderr.sync = true

require 'bundler/setup'

require 'sinatra/base'
require 'htmlentities'

require 'parallel'
require 'excon'
require 'json'
require 'logger'
require 'cgi'

class WebServer < Sinatra::Base
  helpers do
    def repo
      settings.repo
    end

    def h(text)
      HTMLEntities.new.encode(text)
    end
  end

  set :expire, nil

  get '/' do
    @jobs = repo.query({
      remote_only: params.fetch('remote', false) == 'true'
    })

    expires(settings.expire, :public) if settings.expire?

    erb(:index)
  end
end

class JobAd
  class << self
    def from_hn(data)
      new.tap do |job|
        job.id = data.fetch('id')
        job.timestamp = Time.at(data.fetch('time'))
        job.text = data.fetch('text').
          split('<p>').
          first.
          gsub(/<a[^>]+>.+<\/a>+/, "").
          strip
      end
    end
  end

  attr_accessor :id, :text, :timestamp

  def initialize(id: nil, text: nil, timestamp: nil)
    @id = id
    @text = text
    @timestamp = timestamp
  end

  def remote?
    to_s.match?(/REMOTE/)
  end

  def to_s
    HTMLEntities.new.decode(text)
  end
end

class JobFetcher
  # USER_ID = 'whoshiring'
  # ITEM = '16282819'
  #
  def initialize(item, logger = Logger.new($stderr))
    @item = item
    @logger = logger
  end

  def get(client = Excon)
    parent_connection = client.new("https://hacker-news.firebaseio.com/v0/item/#{item}.json?print=pretty")
    parent_response = parent_connection.request method: :get, expects: [ 200 ]

    child_ids = JSON.parse(parent_response.body).fetch('kids')
    jobs = Parallel.map(child_ids, in_threads: 4) do |id|
      child_connection = client.new("https://hacker-news.firebaseio.com/v0/item/#{id}.json?print=pretty")
      child_response = child_connection.request method: :get, expects: [ 200 ]
      data = JSON.parse(child_response.body)

      if data.nil?
        logger.info(self.class) { "#{id} did not parse into JSON" }
        nil
      elsif data.fetch('deleted', false)
        logger.info(self.class) { "#{id} deleted" }
        nil
      else
        logger.info(self.class) { "processing #{id}" }
        JobAd.from_hn(data)
      end
    end

    jobs.compact
  end

  private
  def logger
    @logger
  end

  def item
    @item
  end
end
