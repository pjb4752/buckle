require 'buckle/reading'

module Buckle
  module Compilation
    def self.compile(input)
      Reader.read(input)
    end
  end
end
