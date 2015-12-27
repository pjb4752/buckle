require 'buckle/types/any'

module Buckle
  module Types
    class List < Any

      def initialize(value = [])
        super(value)
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
