require "ostruct"

module GocdClient
  module Models
    class Job < OpenStruct
      def scheduled_date
        unix_timestamp = super/1000.0
        Time.at(unix_timestamp)
      end   
    end
  end
end