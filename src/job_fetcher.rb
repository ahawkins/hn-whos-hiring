require 'excon'
require 'parallel'

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

