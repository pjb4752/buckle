require 'buckle/types/all'
require 'securerandom'

module Buckle
  module Compilation
    class Analyzer
      include Types::Converters
      include Types::CollectionHelpers

      SPECIAL_FORMS = [:def, :fn, :if, :let]

      BUILTINS = Types::Map.new({
        Types::Symbol.new(:write) => Types::Map.new({ arity: 1 }),
        Types::Symbol.new(:read) => Types::Map.new({ arity: 1 }),
        Types::Symbol.new(:+) => Types::Map.new({ arity: 2 }),
        Types::Symbol.new(:-) => Types::Map.new({ arity: 2 })
      })

      def initialize(error_klass, env = Types::Map.new)
        @error_klass = error_klass
        @env = env

        [:symbols, :globals].each do |sym|
          @env.value[Types::Keyword.new(sym)] ||= Types::Map.new
        end
      end

      def build_ast(forms)
        analyzed = forms.value.map do |form|
          new_scope(env)
          analyze(form)
        end

        return Types::Vector.new(analyzed), env
      end

      private

      attr_reader :error_klass, :env

      def error(message)
        raise error_klass, message
      end

      def new_scope(env)
        env.value[Types::Keyword.new(:locals)] = Types::Vector.new
      end

      def generate_id
        SecureRandom.uuid
      end

      def register_global(symbol, expr)
        global_id = generate_id
        globals = env.value[Types::Keyword.new(:globals)]
        globals.value[symbol] = global_id

        symbol_table = env.value[Types::Keyword.new(:symbols)]
        symbol_table.value[global_id] = Types::Map.new({
          name: symbol,
          id: global_id,
          type: Types::Keyword.new(:global),
          value: expr
        })

        global_id
      end

      def global_exists?(symbol)
        !global_lookup(symbol).nil?
      end

      def global_lookup(symbol)
        env.value[Types::Keyword.new(:globals)].value[symbol]
      end

      def local_lookup(symbol)
        names = env.value[Types::Keyword.new(:locals)]
        names.value.reverse.reduce(nil) { |acc, l| acc || l.value[symbol] }
      end

      def resolve_var(symbol)
        local_lookup(symbol) || global_lookup(symbol)
      end

      def nonsymbol_names?(form)
        !even_entries(form).value.all?(&:symbol?)
      end

      def nonsymbol_values?(form)
        !form.value.all?(&:symbol?)
      end

      def special?(symbol)
        special_forms.map { |f| Types::Symbol.new(f) }.include?(symbol)
      end

      def special_values?(form)
        odd_entries(form).value.find { |f| special?(f) }
      end

      def special_forms
        SPECIAL_FORMS
      end

      def builtin?(symbol)
        res = builtins.value.find { |k, _| k == symbol }
        res && res.last
      end

      def builtins
        BUILTINS
      end

      def analyze(form)
        if form.number? || form.string? || form.keyword?
          analyze_literal(form)
        elsif form.symbol?
          analyze_symbol(form)
        elsif form.list?
          analyze_list(form)
        else
          form
        end
      end

      def analyze_literal(form)
        Types::Map.new({
          op: Types::Keyword.new(:literal),
          type: Types::Keyword.new(form.type),
          expr: form
        })
      end

      def analyze_symbol(symbol)
        if special?(symbol)
          error("cannot take value of special form #{symbol}")
        elsif function = builtin?(symbol)
          analyze_builtin(symbol, function)
        elsif var = resolve_var(symbol)
          analyze_var(symbol, var)
        else
          error("undefined symbol: #{symbol.value}")
        end
      end

      def analyze_list(list)
        if list.first.symbol? && special?(list.first)
          analyze_special(list.first, list.rest)
        elsif list.first.symbol? || list.first.list?
          first = analyze(list.first)

          if first.value[Types::Keyword.new(:op)] == Types::Keyword.new(:fn)
            analyze_application(first, list.rest)
          else
            type = first.value[Types::Keyword.new(:type)]
            error("cannot apply instance of #{type}")
          end
        else
          error("cannot apply instance of #{first.class}")
        end
      end

      def analyze_special(symbol, rest)
        send(:"analyze_#{symbol.value}", rest)
      end

      def analyze_var(symbol, var_id)
        Types::Map.new({
          op: Types::Keyword.new(:var),
          name: symbol,
          id: var_id
        })
      end

      def analyze_def(forms)
        name = forms.first
        expr = forms.second

        if name.nil? || expr.nil?
          error('invalid number of terms in def')
        elsif !name.symbol?
          error('first form must be symbol in def')
        elsif expr.symbol? && special?(expr)
          error("cannot take value of special: #{expr}")
        elsif global_exists?(name)
          error("cannot redefine symbol #{name}")
        else
          value = analyze(expr)

          # check name here again for nested def
          if global_exists?(name)
            error("cannot redefine symbol #{name}")
          end
          var_id = register_global(name, value)
          Types::Map.new({
            op: Types::Keyword.new(:def),
            id: var_id,
            name: name,
            init: value
          })
        end
      end

      def analyze_let(forms)
        bindings = forms.first
        exprs = forms.rest

        if bindings.nil?
          error('no binding vector in let')
        elsif !bindings.vector?
          error('first form must be bindings vector in let')
        elsif bindings.value.size.odd?
          error('bindings must contain even number of forms in let')
        elsif nonsymbol_names?(bindings)
          error('binding names must be symbols in let')
        elsif symbol = special_values?(bindings)
          error("cannot take value of special: #{symbol}")
        else
          Types::Map.new({
            op: Types::Keyword.new(:let),
            bindings: analyze_bindings(bindings),
            expr: analyze_subforms(exprs)
          })
        end
      end

      def analyze_fn(forms)
        params = forms.first
        exprs = forms.rest

        if params.nil?
          error('no params vector in fn')
        elsif !params.vector?
          error('first form must be a params vector in fn')
        elsif nonsymbol_values?(params)
          error('params vector must contain only symbols in fn')
        elsif params.value.uniq.size < params.value.size
          error('duplicate params given in fn')
        else
          Types::Map.new({
            op: Types::Keyword.new(:fn),
            type: Types::Keyword.new(:udf),
            id: generate_id,
            arity: params.value.size,
            params: analyze_params(params),
            expr: analyze_subforms(exprs)
          })
        end
      end

      def analyze_builtin(symbol, function)
        Types::Map.new({
          op: Types::Keyword.new(:fn),
          type: Types::Keyword.new(:builtin),
          name: symbol,
          arity: function.value[Types::Keyword.new(:arity)]
        })
      end

      def analyze_if(rest)
        if rest.value.size != 3
          error('wrong number of forms in if')
        else
          Types::Map.new({
            op: Types::Keyword(:if),
            test: analyze(rest.first),
            then: analyze(rest.second),
            else: analyze(rest.third)
          })
        end
      end

      def analyze_application(fn, args)
        if args.value.size != fn.value[Types::Keyword.new(:arity)]
          error('arity mismatch in apply')
        else
          fntype = fn.value[Types::Keyword.new(:type)]
          target = fntype == Types::Keyword.new(:builtin) ?
            fn.value[Types::Keyword.new(:name)] :
            target = fn.value[Types::Keyword.new(:id)]
          Types::Map.new({
            op: Types::Keyword.new(:apply),
            fntype: fntype,
            target: target,
            args: analyze_subforms(args)
          })
        end
      end

      def analyze_params(symbols)
        analyzed = Types::Vector.new
        symbol_table = env.value[Types::Keyword.new(:symbols)]
        local_names = env.value[Types::Keyword.new(:locals)]
        scope = local_names.value.push(Types::Map.new) # ::Array, not Vector

        symbols.value.each do |symbol|
          var_id = generate_id
          scope.last.value[symbol] = var_id
          attrs = { name: symbol, id: var_id }
          analyzed.value.push(Types::Map.new(attrs))
          symbol_table.value[var_id] = Types::Map.new(
            attrs.merge({ type: Types::Keyword.new(:param) }))
        end

        analyzed
      end

      def analyze_bindings(bindings)
        # TODO some duplication here
        analyzed = Types::Vector.new
        symbol_table = env.value[Types::Keyword.new(:symbols)]
        local_names = env.value[Types::Keyword.new(:locals)]
        scope = local_names.value.push(Types::Map.new) # ::Array, not Vector

        bindings.value.each_slice(2) do |name, expr|
          analyzed_value = analyze(expr)
          var_id = generate_id
          scope.last.value[name] = var_id
          attrs = { name: name, id: var_id, value: analyzed_value }
          analyzed.value.push(Types::Map.new(attrs))
          symbol_table.value[var_id] = Types::Map.new(
            attrs.merge({ type: Types::Keyword.new(:local) }))
        end

        analyzed
      end

      def analyze_subforms(subforms)
        result = subforms.value.map { |sf| analyze(sf) }
        Types::Vector.new(result)
      end
    end
  end
end
