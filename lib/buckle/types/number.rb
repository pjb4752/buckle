require 'buckle/types/any'

module Buckle
  module Types
    class Number < Any

      def to_s
        value.to_s
      end

      def self.from_chars(chars)
        self.new(chars.join.to_i)
      end
    end
  end
end
