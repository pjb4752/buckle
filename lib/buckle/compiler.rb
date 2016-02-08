require 'buckle/compilation/analyzer'
require 'buckle/compilation/emitter'

module Buckle
  class Compiler

    CompilationError = Class.new(StandardError)

    def compile(forms)
      ast, env = analyze(forms)
      emit(ast, env)
    end

    private

    def analyze(forms)
      analyzer.build_ast(forms)
    end

    def emit(ast, env)
      emitter(ast, env).emit_bytecode
    end

    def analyzer
      @analyzer ||=  Compilation::Analyzer.new(error_klass)
    end

    def emitter(ast, env)
      Compilation::Emitter.new(ast, env)
    end

    def error_klass
      CompilationError
    end
  end
end
