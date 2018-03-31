class JSONClient
  def get(url)
    begin
      JSON.parse(Excon.new(url).request(method: :get, expects: [ 200 ]).body)
    rescue Excon::Error::InternalServerError => ex
      raise APIError, ex
    end
  end
end

APIError = Class.new(StandardError)
