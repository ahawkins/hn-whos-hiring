require_relative '../src/app'

logger = Logger::Better.new($stdout).tap do |log|
	log.level = ENV.fetch('LOG_LEVEL', 'info').to_sym
end

repo = MongoRepo.new(Mongo::Client.new(ENV.fetch('MONGODB_URI'), {
	logger: logger
}))

WebServer.set(:repo, repo)

run WebServer
