require 'buckle/types/any'

module Buckle
  module Types
    class Map < Any

      def initialize(value = {})
        super(value.map { |k, v|
          [k.is_a?(::Symbol) ? Types::Keyword.new(k) : k, v]
        }.to_h)
      end

      def to_s
        '{%s}' % value.map { |k, v| "#{k} #{v}" }.join(' ')
      end

      def self.from_array(values)
        self.new(Hash[*values])
      end
    end
  end
end
