require 'sinatra/base'

class WebServer < Sinatra::Base
  helpers do
    def repo
      settings.repo
    end

    def h(text)
      HTMLEntities.new.encode(text)
    end

    def remote_only?
		  params.fetch('remote', 'false') == 'true'
    end

    def all_jobs?
      !remote_only?
    end
  end

  set :expire, nil

  get '/' do
    @jobs = repo.query({
      remote_only: remote_only?
    })

    expires(settings.expire, :public) if settings.expire?

    erb(:index)
  end
end
