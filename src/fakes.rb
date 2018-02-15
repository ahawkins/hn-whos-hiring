require 'delegate'

class FakeRepo < DelegateClass(Array)
  def initialize
    super([ ])
  end

  def query(remote_only: false)
    if remote_only
      select(&:remote?)
    else
      each
    end
  end
end
