require 'buckle/types/any'

module Buckle
  module Types
    class Vector < Any

      def initialize(value = [])
        super(value)
      end

      def to_s
        '[%s]' % value.map(&:to_s).join(' ')
      end

      def first
        value[0]
      end

      def second
        value[1]
      end

      def self.from_array(values)
        self.new(values)
      end
    end
  end
end
