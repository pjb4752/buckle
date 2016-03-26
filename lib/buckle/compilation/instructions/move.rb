module Buckle
  module Compilation
    class Move

      attr_reader :source, :destination

      def initialize(source, destination)
        @source = source
        @destination = destination
      end

      def to_s
        "mov dst: #{destination}, src: #{source}"
      end
    end
  end
end
