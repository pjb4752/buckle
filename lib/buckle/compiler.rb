require 'buckle/compilation/analyzer'

module Buckle
  class Compiler

    CompilationError = Class.new(StandardError)

    def compile(forms)
      analyze(forms)
    end

    private

    def analyze(forms)
      analyzer.build_ast(forms)
    end

    def analyzer
      @analyzer ||=  Compilation::Analyzer.new(error_klass)
    end

    def error_klass
      CompilationError
    end
  end
end
