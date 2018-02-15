require 'mongo'

class MongoRepo
  COLLECTION = :jobs

  def initialize(client)
    @client = client
  end

  def setup
    client[COLLECTION].indexes.create_one({
      timestamp: -1,
      remote: 1
    })
  end

  def clear
    client[COLLECTION].drop
  end

  def <<(job)
    client[COLLECTION].update_one({
      _id: job.id
    }, {
      '$set' => {
        text: job.to_s,
        timestamp: job.timestamp.to_i,
        remote: job.remote?
      }
    }, {
      upsert: true
    })
    self
  end

  def query(remote_only: false)
    if remote_only
      marshal(client[COLLECTION].find({
        remote: true
      }).sort({ timestamp: -1 }))
    else
      marshal(client[COLLECTION].find.sort({ timestamp: -1 }))
    end
  end

  private
  def client
    @client
  end

  def marshal(list)
    list.map do |data|
      JobAd.new({
        id: data.fetch('_id'),
        text: data.fetch('text'),
        timestamp: Time.at(data.fetch('timestamp'))
      })
    end
  end
end
