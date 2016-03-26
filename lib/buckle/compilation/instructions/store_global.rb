module Buckle
  module Compilation
    class StoreGlobal

      attr_reader :var_id, :register

      def initialize(var_id, register)
        @var_id = var_id
        @register = register
      end

      def to_s
        "storg var_id: #{var_id}, reg: #{register}"
      end
    end
  end
end
