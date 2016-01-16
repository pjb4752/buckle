require 'buckle/types/any'

module Buckle
  module Types
    class Keyword < Any

      def initialize(value)
        super(value.to_s)
      end

      def to_s
        ":#{value}"
      end

      def self.from_chars(chars)
        text = chars.join.sub(/\A:/, '')
        raise ArgumentError, 'invalid keyword' if text.empty?

        self.new(text)
      end
    end
  end
end
