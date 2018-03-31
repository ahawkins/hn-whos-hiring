require 'mongo'

class MongoRepo
  JOB_AD_COLLECTION = :jobs
  FREELANCE_AD_COLLECTION = :freelance_ads

  def initialize(client)
    @client = client
  end

  def setup
    client[JOB_AD_COLLECTION].indexes.create_one({
      timestamp: -1,
      remote: 1
    })
    client[JOB_AD_COLLECTION].indexes.create_one({
      text: 'text'
    })

    client[FREELANCE_AD_COLLECTION].indexes.create_one({
      timestamp: -1,
      seeking_work: 1,
      remote: 1
    })

    client[FREELANCE_AD_COLLECTION].indexes.create_one({
      text: 'text'
    })
  end

  def clear
    client[JOB_AD_COLLECTION].drop
    client[FREELANCE_AD_COLLECTION].drop
  end

  def <<(item)
    case item.class.to_s
    when 'JobAd'
      client[JOB_AD_COLLECTION].update_one({
        _id: item.id
      }, {
        '$set' => {
          text: item.to_s,
          timestamp: item.timestamp.to_i,
          remote: item.remote?
        }
      }, {
        upsert: true
      })
    when 'FreelanceAd'
      client[FREELANCE_AD_COLLECTION].update_one({
        _id: item.id
      }, {
        '$set' => {
          text: item.to_s,
          timestamp: item.timestamp.to_i,
          remote: item.remote?,
          seeking_work: item.seeking_work?
        }
      }, {
        upsert: true
      })
    else
      fail "Cannot store #{item.class}"
    end

    self
  end

  def query_jobs(filter: nil, keyword: nil)
    options = { }

    case filter
    when :remote
      options['remote'] = true
    when nil, :all
      # nothing
    else
      fail ArgumentError, "Unspported filter value: #{filter}"
    end

    if keyword
      options['$text'] = { '$search' => keyword }
    end

    client[JOB_AD_COLLECTION].find(options).sort({ timestamp: -1 }).map do |item|
      JobAd.new({
        id: item.fetch('_id'),
        text: item.fetch('text'),
        timestamp: Time.at(item.fetch('timestamp'))
      })
    end
  end

  def query_freelancers(filter: nil, remote: nil, keyword: nil)
    options = { }

    case filter
    when :seeking_work
      options['seeking_work'] = true
    when :seeking_freelancer
      options['seeking_work'] = false
    when nil, :all
      # nothing
    else
      fail ArgumentError, "Unspported filter value: #{filter}"
    end

    options[:remote] = true if remote

    if keyword
      options['$text'] = { '$search' => keyword }
    end

    client[FREELANCE_AD_COLLECTION].find(options).sort({ timestamp: -1 }).map do |item|
      FreelanceAd.new({
        id: item.fetch('_id'),
        text: item.fetch('text'),
        timestamp: Time.at(item.fetch('timestamp'))
      })
    end
  end

  private
  def client
    @client
  end
end
