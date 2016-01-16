require 'buckle/types/any'

module Buckle
  module Types
    class Symbol < Any

      def initialize(value)
        super(value.to_sym)
      end

      def to_s
        value.to_s
      end

      def self.from_chars(chars)
        self.new(chars.join)
      end
    end
  end
end
