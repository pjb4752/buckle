module Buckle
  module Compilation
    class LoadGlobal

      attr_reader :var_id, :register

      def initialize(var_id, register)
        @var_id = var_id
        @register = register
      end

      def to_s
        "loadg reg: #{register}, var_id: #{var_id}"
      end
    end
  end
end
