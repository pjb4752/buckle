module Buckle
  module Types
    class Any

      SIMPLE_TYPES = ['Number', 'String']

      attr_reader :value

      def initialize(value)
        @value = value
      end

      # method missing to implement type predicates
      # e.g. list?, string?, symbol?, etc.
      def method_missing(name, *arguments)
        str_name = name.to_s

        if str_name =~ /\w+\?/
          klass_name = str_name.sub(/\?/, '').capitalize
          self.class.class_name == klass_name
        else
          raise NoMethodError, "undefined method: #{name}"
        end
      end

      def simple?
        SIMPLE_TYPES.include?(self.class.class_name)
      end

      def self.class_name
        @class_name ||= name.split('::').last
      end
    end
  end
end
