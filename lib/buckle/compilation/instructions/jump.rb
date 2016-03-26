module Buckle
  module Compilation
    class Jump

      attr_reader :label

      def initialize(label)
        @label = label
      end

      def to_s
        "jmp label: #{label}"
      end
    end
  end
end
