require "ostruct"

module GocdClient
  module Models
    class PipelineHistory < OpenStruct
      def pipelines
        super.map do |pipeline_raw| 
          Pipeline.new(pipeline_raw) 
        end
      end
    end
  end
end