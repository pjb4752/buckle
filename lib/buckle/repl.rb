require 'readline'

require 'buckle/compilation'
require 'buckle/exitable'
require 'buckle/form_printer'
require 'buckle/text_stream'

module Buckle
  class Repl
    include Exitable

    attr_reader :printer

    def initialize(printer = FormPrinter.new)
      @printer = printer
    end

    def run
      while input = Readline.readline('> ', true)
        forms = compile(input)
        printer.printall(forms)
      end
      normal_exit
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
  end
end
