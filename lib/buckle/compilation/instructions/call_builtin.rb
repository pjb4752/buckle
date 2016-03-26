module Buckle
  module Compilation
    class CallBuiltin

      attr_reader :name, :arity, :register

      def initialize(name, arity, register)
        @name = name
        @arity = arity
        @register = register
      end

      def to_s
        "callb name: #{name}, arity: #{arity}, reg: #{register}"
      end
    end
  end
end
