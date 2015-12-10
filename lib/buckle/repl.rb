require 'buckle/compilation'
require 'buckle/exitable'
require 'buckle/form_printer'
require 'buckle/text_stream'

module Buckle
  class Repl
    include Exitable

    attr_reader :history, :printer

    def initialize(printer = FormPrinter.new)
      @history = []
      @printer = printer
    end

    def run
      loop do
        input = prompt('> ')

        normal_exit if input.nil?
        input.chomp!
        save_history(input)

        forms = compile(input)
        printer.printall(forms)
      end
    end

    private

    def prompt(message)
      print(message)
      gets
    end

    def compile(input)
      stream = TextStream.from_str(input)
      Compilation.compile(stream)
    end

    def save_history(input)
      history.pop if history.size > 100
      history << input
    end
  end
end
