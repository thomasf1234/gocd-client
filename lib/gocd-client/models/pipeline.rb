require "ostruct"

module GocdClient
  module Models
    class Pipeline < OpenStruct
      def stages
        super.map do |stage_raw| 
          Stage.new(stage_raw) 
        end
      end 
    end
  end
end