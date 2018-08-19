require "gocd-client/version"

require "gocd-client/models/version"
require "gocd-client/models/agent"
require "gocd-client/models/pipeline"
require "gocd-client/models/pipeline_history"
require "gocd-client/models/stage"
require "gocd-client/service"

module GocdClient
  # Your code goes here...
  def self.root
    File.dirname(__dir__)
  end
end
