class ThreadFinder
  def initialize(client = JSONClient.new)
    @client = client
  end

  def locate
    data = client.get("https://hacker-news.firebaseio.com/v0/user/whoishiring.json")
    # Assumes the submissions are ordered by recent first
    data.fetch('submitted')[0..2].find do |id|
      yield client.get("https://hacker-news.firebaseio.com/v0/item/#{id}.json")
    end
  end

  private

  def client
    @client
  end
end
