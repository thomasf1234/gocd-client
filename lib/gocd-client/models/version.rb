require "ostruct"

module GocdClient
  module Models
    class Version < OpenStruct
      def >(version_string)
        Gem::Version.new(version) > Gem::Version.new(version_string)
      end

      def >=(version_string)
        Gem::Version.new(version) > Gem::Version.new(version_string) || self.==(version_string)
      end

      def <(version_string)
        Gem::Version.new(version) < Gem::Version.new(version_string)
      end

      def <=(version_string)
        Gem::Version.new(version) < Gem::Version.new(version_string) || self.==(version_string)
      end

      def ==(version_string)
        Gem::Version.new(version) == Gem::Version.new(version_string)
      end
    end
  end
end