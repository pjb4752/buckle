module Buckle
  module Compilation
    class MoveRetval

      attr_reader :register

      def initialize(register)
        @register = register
      end

      def to_s
        "movret reg: #{register}"
      end
    end
  end
end
