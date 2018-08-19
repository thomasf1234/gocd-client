require "ostruct"

module GocdClient
  module Models
    class Stage < OpenStruct
      module Result
        PASSED = 'Passed'
      end
  
      def passed?
        result == Result::PASSED
      end
  
      def jobs
        super.map do |job_raw| 
          Job.new(job_raw) 
        end
      end    
    end
  end
end