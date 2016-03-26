module Buckle
  module Compilation
    class JumpFalse

      attr_reader :register, :label

      def initialize(register, label)
        @register = register
        @label = label
      end

      def to_s
        "jmpf reg: #{register}, label: #{label}"
      end
    end
  end
end
