require 'logger'
require 'excon'
require 'parallel'
require 'json'

class JobFetcher
  class ExconClient
    def get(url)
      JSON.parse(Excon.new(url).request(method: :get, expects: [ 200 ]).body)
    end
  end

  def initialize(item, logger = Logger.new($stderr))
    @item = item
    @logger = logger
  end

  def get(client = ExconClient.new, threads: 4)
    parent = client.get("https://hacker-news.firebaseio.com/v0/item/#{item}.json")

    child_ids = parent.fetch('kids')
    jobs = Parallel.map(child_ids, in_threads: threads) do |id|
      data = client.get("https://hacker-news.firebaseio.com/v0/item/#{id}.json")

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
