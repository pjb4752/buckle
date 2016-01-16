module Buckle
  module Types
    class Any

      attr_reader :value

      def initialize(value)
        @value = value
      end

      # method missing to implement type predicates
      # e.g. list?, string?, symbol?, etc.
      def method_missing(name, *arguments)
        str_name = name.to_s

        if str_name =~ /\w+\?/ && Types::NAMES.include?(str_name.chop)
          klass_name = str_name.sub(/\?/, '').capitalize
          self.class.class_name == klass_name
        else
          raise NoMethodError, "undefined method: #{name}"
        end
      end

      # return typename e.g. list, string, symbol etc.
      def type
        self.class.class_name.downcase
      end

      # override for hash-key equality
      def ==(other)
        self.class == other.class && value == other.value
      end
      alias_method :eql?, :==

      def hash
        value.hash
      end

      private

      def self.class_name
        @class_name ||= name.split('::').last
      end
    end
  end
end
