require 'readline'

require 'buckle/evaluator'
require 'buckle/exitable'
require 'buckle/printer'
require 'buckle/text_stream'

module Buckle
  class Repl
    include Exitable

    attr_reader :options, :evaluator, :printer

    def initialize(options, evaluator = Evaluator.new, printer = Printer.new)
      @options = options
      @evaluator = evaluator
      @printer = printer
    end

    def run
      while raw = Readline.readline('> ', true)
        input = to_stream(raw)
        result = evaluate(input)

        printer.printall(result)
      end
      normal_exit
    end

    private

    def to_stream(input)
      TextStream.from_str(input)
    end

    def evaluate(input)
      evaluator.evaluate(input)
    end
  end
end
