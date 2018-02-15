require_relative '../src/app'
require_relative '../src/fakes'

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
