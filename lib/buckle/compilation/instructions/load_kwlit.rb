module Buckle
  module Compilation
    class LoadKwlit

      attr_reader :value, :register

      def initialize(value, register)
        @value = value
        @register = register
      end

      def to_s
        "movlkw reg: #{register}, val: #{value}"
      end
    end
  end
end
