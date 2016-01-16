require 'readline'

require 'buckle/compiler'
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
        do_loop(input)
      end
      normal_exit
    end

    private

    def do_loop(input)
      result = evaluate(input)
      printer.printall(result)
    rescue Compiler::CompilationError => e
      printer.error("compilation error: #{e.message}")
    end

    def to_stream(input)
      TextStream.from_str(input)
    end

    def evaluate(input)
      evaluator.evaluate(input)
    end
  end
end
