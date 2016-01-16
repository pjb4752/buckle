require 'buckle/types/any'

module Buckle
  module Types
    class List < Any

      def initialize(value = [])
        super(value)
      end

      def first
        value[0]
      end

      def second
        value[1]
      end

      def third
        value[2]
      end

      def rest(nth: 1)
        self.class.new(value[nth...value.size])
      end

      def to_s
        '(%s)' % value.map(&:to_s).join(' ')
      end

      def self.from_array(values)
        self.new(values)
      end
    end
  end
end
