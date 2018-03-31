class ItemFetcher
  def initialize(client: JSONClient.new, logger: NullLogger.new)
    @client = client
    @logger = logger
  end

  def get(item, threads: 4)
    logger.info(self.class) { "Crawling #{item}" }

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

        yield data if block_given?
      end
    end

    jobs.compact
  end

  private

  def client
    @client
  end

  def logger
    @logger
  end
end
