module Buckle
  module Compilation
    class LoadStrlit

      attr_reader :value, :register

      def initialize(value, register)
        @value = value
        @register = register
      end

      def to_s
        "movlstr reg: #{register}, val: #{value}"
      end
    end
  end
end
