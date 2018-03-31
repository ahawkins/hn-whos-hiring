require 'rss'
require 'sinatra/base'

class WebServer < Sinatra::Base
  helpers do
    def repo
      settings.repo
    end

    def html_encode(text)
      HTMLEntities.new.encode(text)
    end

    def titleize(ad)
      if ad.is_a?(JobAd)
        titleize_job_ad(ad)
      elsif ad.is_a?(FreelanceJob)
        titleize_freelance_ad(ad)
      else
        fail "Cannot titleize #{ad}"
      end
    end

    def titleize_job_ad(ad)
      if ad.title?
        truncate(sanitize(ad.title))
      else
        truncate(sanitize(ad.text))
      end
    end

    def titleize_freelance_ad(ad)
      if ad.title?
        truncate(ad.title)
      else
        truncate(ad.text)
      end
    end

    def sanitize(text)
      text.
        gsub(/<a[^>]+>.+<\/a>+/, "").
        gsub(/\(\s*\)/, '').
        split('|').
        map(&:strip).
        reject(&:empty?).
        join(' | ')
    end

    def truncate(string, length: 100, tail: '...')
      if string.length > length - tail.length
        string[0..(length - tail.length)] + tail
      else
        string
      end
    end

    def remote?
      params['remote'] == 'true' || params['filter'] == 'remote'
    end

    def query_filter
      if params.key?('filter')
        params.fetch('filter').to_sym
      else
        nil
      end
    end

    def seeking_work?
      params['filter'] == 'seeking_work'
    end

    def seeking_freelancer?
      params['filter'] == 'seeking_freelancer'
    end

    def all_posts?
      params['filter'].nil? || params['filter'] == 'all'
    end

    def keyword
      if params.fetch('q', '').empty?
        nil
      else
        params.fetch('q')
      end
    end

    def jobs_page?
      @navbar_link == :jobs
    end

    def freelancers_page?
      @navbar_link == :freelancers
    end
  end

  get '/' do
    @navbar_link = :jobs

    @ads = repo.query_jobs({
      filter: query_filter,
      keyword: keyword
    })

    erb(:jobs)
  end

  get '/freelancers' do
    @navbar_link = :freelancers

    @ads = repo.query_freelancers({
      filter: query_filter,
      remote: remote?,
      keyword: keyword
    })

    erb(:freelancers)
  end

  get '/rss' do
    jobs = repo.query_jobs({
      filter: query_filter,
      keyword: keyword
    })

    rss = RSS::Maker.make("rss2.0") do |maker|
      maker.channel.author = "HackerNews"
      maker.channel.updated = Time.now.to_s
      maker.channel.about = "https://news.ycombinator.com/user?id=whoishiring"
      maker.channel.title = "HackerNews: Who is Hiring?"
      maker.channel.description = "Post summaries"
      maker.channel.link = request.url

      jobs.each do |job|
        maker.items.new_item do |item|
          item.link = job.link
          item.title = titleize(job)
          item.description = job.text
          item.updated = job.timestamp.to_s
          item.guid.content = job.id
        end
      end
    end

    content_type 'application/rss+xml', charset: 'utf-8'
    body rss.to_s
  end

  get '/rss/freelancers' do
    ads = repo.query_freelancers({
      filter: query_filter,
      remote: remote?,
      keyword: keyword
    })

    rss = RSS::Maker.make("rss2.0") do |maker|
      maker.channel.author = "HackerNews"
      maker.channel.updated = Time.now.to_s
      maker.channel.about = "https://news.ycombinator.com/user?id=whoishiring"
      maker.channel.title = "HackerNews: Freelancer? Seeking Freelancer?"
      maker.channel.description = "Post summaries"
      maker.channel.link = request.url

      ads.each do |ad|
        maker.items.new_item do |item|
          item.link = ad.link
          item.title = titleize(ad)
          item.description = ad.text
          item.updated = ad.timestamp.to_s
          item.guid.content = ad.id
        end
      end
    end

    content_type 'application/rss+xml', charset: 'utf-8'
    body rss.to_s
  end
end
