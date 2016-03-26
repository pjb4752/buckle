module Buckle
  module Compilation
    class LoadNumlit

      attr_reader :value, :register

      def initialize(value, register)
        @value = value
        @register = register
      end

      def to_s
        "movlnum reg: #{register}, val: #{value}"
      end
    end
  end
end
