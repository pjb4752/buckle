require 'buckle/printing'
require 'buckle/reading'

module Buckle
  module Compilation
    def self.compile(input)
      sexprs = Reading.read(input)
      Printing.dump_forms(sexprs)
    end
  end
end
