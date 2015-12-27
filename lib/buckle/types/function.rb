require 'buckle/types/any'

module Buckle
  module Types
    class Function < Any

      def to_s
        '<function>'
      end
    end
  end
end
