module Buckle
  module Compilation
    class MoveLabel

      attr_reader :register, :label

      def initialize(register, label)
        @register = register
        @label = label
      end

      def to_s
        "movlbl reg: #{register}, lbl: #{label}"
      end
    end
  end
end
