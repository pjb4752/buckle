require 'buckle/types/all'
require 'buckle/compilation/instructions/all'
require 'securerandom'

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

      def <<(bytecode)
        bytecodes << bytecode
      end
    end

    class RegisterSet
      def initialize
        @frames = [0x0001]
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
        last_value = current

        yield

        self.current = last_value
      end

      def with_frame
        frames.push(0x0001)

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

      def generate_label
        SecureRandom.uuid
      end

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
        when kw(:if)
          emit_if(node)
        when kw(:apply)
          emit_apply(node)
        end
      end

      def emit_literal(node)
        value = node.value[kw(:expr)]

        case node.value[kw(:type)]
        when kw(:number)
          codes << LoadNumlit.new(value, registers.current)
        when kw(:string)
          codes << LoadStrlit.new(value, registers.current)
        when kw(:keyword)
          codes << LoadKwlit.new(value, registers.current)
        else
          fail 'invalid literal type'
        end

        if node.value[kw(:return)]
          codes << ReturnFn.new(registers.current)
        end
      end

      def emit_var(node)
        var_id = node.value[kw(:id)]
        var_ctx = node.value[kw(:context)]
        symbol_table = env.value[kw(:symbols)]
        var = symbol_table.value[var_id]

        case var.value[kw(:type)]
        when kw(:global)
          codes << LoadGlobal.new(var_id, registers.current)
        when kw(:param)
          mappings = env.value[kw(:registers)]
          register = mappings.value[var_id]

          codes << Move.new(register, registers.current)
        else
          fail 'unknown var type'
        end

        if node.value[kw(:return)]
          codes << ReturnFn.new(registers.current)
        end
      end

      def emit_def(node)
        var_id = node.value[kw(:id)]

        emit(node.value[kw(:init)])
        codes << StoreGlobal.new(var_id, registers.current)

        if node.value[kw(:return)]
          codes << ReturnFn.new(registers.current)
        end
        # shouldn't need this, value is already in registers.current
        # codes.load_global(var_id, registers.current)
      end

      def emit_fn(node)
        exprs = node.value[kw(:expr)]
        arity = node.value[kw(:arity)]
        params = node.value[kw(:params)]
        var_ids = params.value.map { |p| p.value[kw(:id)] }

        # TODO how do we handle passing fn as var?
        label = Label.new(node.value[kw(:id)])
        codes << label
        with_locals(var_ids) do
          exprs.value.each do |expr|
            emit(expr)
          end
        end
        codes << MoveLabel.new(registers.current, label)

        if node.value[kw(:return)]
          codes << ReturnFn.new(registers.current)
        end
      end

      def emit_if(node)
        else_label = generate_label
        retpos = node.value[kw(:return)]
        registers.with_state do
          emit(node.value[kw(:test)])
        end
        codes << JumpFalse.new(registers.current, else_label)

        end_label = generate_label
        registers.with_state do
          emit(node.value[kw(:then)])
        end
        codes << Jump.new(end_label)
        codes << Label.new(else_label)

        registers.with_state do
          emit(node.value[kw(:else)])
        end
        codes << Label.new(end_label)
        codes << ReturnFn.new(registers.current)
      end

      def emit_apply(node)
        case node.value[kw(:fntype)]
        when kw(:builtin)
          name = node.value[kw(:target)]
          arguments = node.value[kw(:args)]
          arity = arguments.value.size
          registers.with_state do
            arguments.value.each do |argument|
              emit(argument)
              registers.inc
            end
          end

          codes << CallBuiltin.new(name, arity, registers.current)
          codes << MoveRetval.new(registers.current)
          # pretty sure we don't need this...
          # VM should place retun value in lowest register
          #codes.ret_builtin(registers.current)
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
            obj[id] = registers.current
            registers.inc
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
