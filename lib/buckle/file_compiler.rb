require 'buckle/compilation'
require 'buckle/form_printer'
require 'buckle/text_stream'

module Buckle
  class FileCompiler

    attr_reader :filenames, :printer

    def initialize(filenames, printer = FormPrinter.new)
      @filenames = filenames
      @printer = printer
    end

    def compile
      filenames.each do |filename|
        code = compile_file(filename)
        printer.printall(code)
      end
    end

    private

    def compile_file(filename)
      stream = TextStream.from_file(filename)
      Compilation.compile(stream)
    end
  end
end
