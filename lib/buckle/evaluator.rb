require 'buckle/compiler'
require 'buckle/reader'

module Buckle
  class Evaluator

    attr_reader :reader, :compiler

    def initialize(reader = Reader.new, compiler = Compiler.new)
      @reader = reader
      @compiler = compiler
    end

    def evaluate(input)
      forms = reader.read(input)
      compiler.analyze(forms)
    end
  end
end
