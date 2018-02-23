require_relative '../src/app'

require 'delegate'
require 'yaml'

class FakeRepo < DelegateClass(Array)
  def initialize
    super([ ])
  end

  def query(remote_only: false, keyword: nil)
    select do |job|
      flag = true

      flag &&= job.remote? if remote_only
      flag &&= job.text.include?(keyword) if keyword

      flag
    end.sort do |j1, j2|
      j2.timestamp <=> j1.timestamp
    end
  end
end

repo = FakeRepo.new

YAML.load_file('fixtures.yml').shuffle[0..50].each do |job|
  repo << job
end

WebServer.set(:repo, repo)

run WebServer
