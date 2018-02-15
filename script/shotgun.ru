require_relative '../src/app'

require 'delegate'

class FakeRepo < DelegateClass(Array)
  def initialize
    super([ ])
  end

  def query(remote_only: false)
    if remote_only
      select(&:remote?).sort do |j1, j2|
        j2.timestamp <=> j1.timestamp
      end
    else
      sort do |j1, j2|
        j2.timestamp <=> j1.timestamp
      end
    end
  end
end

repo = FakeRepo.new

(1..50).each do |i|
	repo << JobAd.new({
		id: i,
		text: 'Foo | Bar',
		timestamp: Time.now
	})

	repo << JobAd.new({
		id: i + 50,
		text: 'Foo | Bar | Remote',
		timestamp: Time.now
	})
end

WebServer.set(:repo, repo)

run WebServer
