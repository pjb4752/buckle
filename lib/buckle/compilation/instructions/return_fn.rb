module Buckle
  module Compilation
    class ReturnFn

      attr_reader :register

      def initialize(register)
        @register = register
      end

      def to_s
        "retfn reg: #{register}"
      end

    end
  end
end
