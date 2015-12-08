require 'buckle/printing'
require 'buckle/reading'

module Buckle
  module Compilation
    def self.compile(input)
      sexprs = Reading.read(input)
      Printing.dump(forms)
    end
  end
end
