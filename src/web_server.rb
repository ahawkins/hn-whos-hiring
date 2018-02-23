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

    def titleize(job)
      if job.title?
        truncate(sanitize(job.title))
      else
        truncate(sanitize(job.text))
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

    def remote_only?
      params['remote'] == 'true' || params['filter'] == 'remote'
    end

    def all_jobs?
      !remote_only?
    end

    def keyword
      if params.fetch('q', '').empty?
        nil
      else
        params.fetch('q')
      end
    end
  end

  get '/' do
    @jobs = repo.query({
      remote_only: remote_only?,
      keyword: keyword
    })

    erb(:index)
  end

  get '/rss' do
    jobs = repo.query({
      remote_only: remote_only?
    })

    rss = RSS::Maker.make("rss2.0") do |maker|
      maker.channel.author = "HackerNews"
      maker.channel.updated = Time.now.to_s
      maker.channel.about = "https://news.ycombinator.com/user?id=whoishiring"
      maker.channel.title = "HackerNews Who's Hiring"
      maker.channel.description = "Summaries of job postings"
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
end
