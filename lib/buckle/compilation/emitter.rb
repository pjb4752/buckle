require 'buckle/types/all'

module Buckle
  module Compilation
    # TODO also use this in analyzer
    class KeywordCache
      def initialize
        @cache = {}
      end

      def lookup(symbol)
        @cache[symbol] ||= Types::Keyword.new(symbol)
      end
    end

    class BytecodeStream
      attr_reader :bytecodes

      def initialize
        @bytecodes = []
      end

      def load_numlit(value, register)
        load_lit('num', value, register)
      end

      def load_strlit(value, register)
        load_lit('str', value, register)
      end

      def load_kwlit(value, register)
        load_lit('kw', value, register)
      end

      def store_global(var_id, register)
        bytecodes << "storg #{var_id}, #{register}"
      end

      def load_global(var_id, register)
        bytecodes << "loadg #{register}, #{var_id}"
      end

      def call_builtin(name, arity, register)
        bytecodes << "callb #{name}, #{arity}, #{register}"
      end

      def ret_builtin(register)
        bytecodes << "retb #{register}"
      end

      def mark_fn(id)
        bytecodes << ".#{id}"
      end

      def end_fn(id)
        bytecodes << "\n\n"
      end

      protected

      def load_lit(type, value, register)
        bytecodes << "movl#{type} #{register}, #{value}"
      end
    end

    class RegisterSet
      def initialize
        @frames = [0x0000]
      end

      def current
        frames.last
      end

      def inc
        self.current = current + 1
      end

      def dec
        self.current = current - 1
      end

      def with_state
        last_value = current + 1

        yield

        self.current = last_value
      end

      def with_frame
        frames.push(0x0000)

        yield

        frames.pop
      end

      protected

      attr_reader :frames

      def current=(value)
        frames[frames.size-1] = value
      end
    end

    class Emitter

      def initialize(ast, env,
                     registers = RegisterSet.new,
                     codes = BytecodeStream.new,
                     cache = KeywordCache.new)
        @ast = ast
        @env = env
        @registers = registers
        @codes = codes
        @cache = cache
      end

      def emit_bytecode
        ast.value.each do |form|
          emit(form)
        end

        Types::Vector.new(codes.bytecodes)
      end

      private

      attr_reader :ast, :env, :registers, :codes, :cache

      def emit(node)
        case node.value[kw(:op)]
        when kw(:literal)
          emit_literal(node)
        when kw(:var)
          emit_var(node)
        when kw(:def)
          emit_def(node)
        when kw(:fn)
          emit_fn(node)
        when kw(:apply)
          emit_apply(node)
        end
      end

      def emit_literal(node)
        value = node.value[kw(:expr)]

        case node.value[kw(:type)]
        when kw(:number)
          codes.load_numlit(value, registers.inc)
        when kw(:string)
          codes.load_strlit(value, registers.inc)
        when kw(:keyword)
          codes.load_kwlit(value, registers.inc)
        else
          fail 'invalid literal type'
        end
      end

      def emit_var(node)
        var_id = node.value[kw(:id)]
        symbol_table = env.value[kw(:symbols)]
        var = symbol_table.value[var_id]

        case var.value[kw(:type)]
        when kw(:global)
          codes.load_global(var_id, registers.inc)
        when kw(:param)
          # thinking
        else
          fail 'unknown var type'
        end
      end

      def emit_def(node)
        var_id = node.value[kw(:id)]

        emit(node.value[kw(:init)])
        codes.store_global(var_id, registers.current)
        # shouldn't need this, value is already in registers.current
        # codes.load_global(var_id, registers.current)
      end

      def emit_fn(form)
        exprs = form.value[kw(:expr)]
        arity = form.value[kw(:arity)]
        params = form.value[kw(:params)]
        var_ids = params.value.map { |p| p.value[kw(:id)] }

        with_locals(var_ids) do
          exprs.value.each do |expr|
            emit(expr)
          end
        end
      end

      def emit_apply(form)
        case form.value[kw(:fntype)]
        when kw(:builtin)
          name = form.value[kw(:target)]
          arguments = form.value[kw(:args)]
          arity = arguments.value.size
          registers.with_state do
            arguments.value.each do |argument|
              emit(argument)
            end
          end

          codes.call_builtin(name, arity, registers.current)
          codes.ret_builtin(registers.current)
        else
          fail 'no udf application yet'
        end
      end

      def kw(symbol)
        cache.lookup(symbol)
      end

      def with_locals(var_ids)
        registers.with_frame do
          mappings = var_ids.each_with_object({}) do |id, obj|
            obj[id] = registers.inc
          end

          old_registers = env.value[kw(:registers)]
          env.value[kw(:registers)] = Types::Map.new(mappings)

          yield

          env.value[kw(:registers)] = old_registers
        end
      end
    end
  end
end
