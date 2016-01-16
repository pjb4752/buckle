module Buckle
  module Types

    NAMES = %w[function keyword list map number string symbol vector]

    NAMES.each do |type|
      require "buckle/types/#{type}"
    end

    module Converters

      def symbolize(value)
        Types::Symbol.new(value)
      end

      def keywordize(value)
        Types::Keyword.new(value)
      end
    end

    module CollectionHelpers

      def even_entries(form)
        entries(form) { |_, i| i.even? }
      end

      def odd_entries(form)
        entries(form) { |_, i| i.odd? }
      end

      private

      def entries(form, &block)
        result = form.value.select.with_index(&block)
        Types::Vector.new(result)
      end
    end
  end
end
