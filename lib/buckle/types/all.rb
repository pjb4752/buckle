require 'buckle/types/function'
require 'buckle/types/keyword'
require 'buckle/types/list'
require 'buckle/types/map'
require 'buckle/types/number'
require 'buckle/types/string'
require 'buckle/types/symbol'
require 'buckle/types/vector'

module Buckle
  module Types
    module Helpers

      def self.wrap_collections(values)
        case values
        when Array then wrap_list(values)
        when Hash then wrap_map(values)
        else values
        end
      end

      def self.wrap_list(list)
        Types::List.new(list.map { |v| wrap_collections(v) })
      end

      def self.wrap_map(map)
        rb_hash = map.reduce(Hash.new) do |acc, (k, v)|
          k, v = wrap_pair(k, v)
          acc.merge(k => v)
        end

        Types::Map.new(rb_hash)
      end

      private

      def self.wrap_pair(k, v)
        [wrap_key(k), wrap_collections(v)]
      end

      def self.wrap_key(k)
        k.is_a?(::Symbol) ? Types::Keyword.new(k) : k
      end
    end
  end
end
