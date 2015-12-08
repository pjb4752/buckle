module Buckle
  module ReaderDSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    InvalidReaderError = Class.new(StandardError)

    class Reader
      attr_reader :name, :each, :post

      def initialize(name, each, post)
        @name = name
        @each = each
        @post = post
      end

      def read(instance, input)
        memo = []
        loop do
          char = input.getc
          break if yield char
          result = instance.instance_exec(input, char, &each)
          memo << result unless result.nil?
        end
        post.call(memo)
      end
    end

    class MatchReader < Reader
      attr_reader :match, :nonmatch

      def initialize(name, match, nonmatch, each, post)
        super(name, each, post)

        @match = match
        @nonmatch = nonmatch
      end

      def begin_expr?(input, char)
        test_and_unget(input, char, &match)
      end

      def read(instance, input)
        super(instance, input) do |char|
          char.nil? || nonmatch_handled?(input, char)
        end
      end

      private

      def test_and_unget(input, char)
        if yield char
          input.ungetc(char)
          true
        else
          false
        end
      end

      def nonmatch_handled?(input, char)
        test_and_unget(input, char, &nonmatch)
      end
    end

    class DelimitedReader < Reader
      attr_reader :open, :close

      def initialize(name, open, close, each, post)
        super(name, each, post)

        @open = open
        @close = close
      end

      def begin_expr?(input, char)
        char == open
      end

      def read(instance, input)
        super(instance, input) do |char|
          raise_eos_error if char.nil?
          end_expr?(char)
        end
      end

      private

      def end_expr?(char)
        char == close
      end

      def raise_eos_error
        raise SyntaxError, 'unexpected end of stream'
      end
    end

    module ClassMethods
      def defreader(name, match: nil, nonmatch: nil,
                    delimiters: nil, each: nil, post: nil)
        if match.nil? && (delimiters.nil? || delimiters.empty?)
          raise InvalidReaderError, 'must specify one of match or delimiters'
        end

        each, post = extract_processors(each, post)
        if match
          match_l, nonmatch_l = extract_matchers(match, nonmatch)
          readers << MatchReader.new(name, match_l, nonmatch_l, each, post)
        else
          open, close = extract_delimiters(delimiters)
          readers << DelimitedReader.new(name, open, close, each, post)
        end
      end

      private

      def extract_processors(each, post)
        default_each = lambda { |input, char| char }
        default_post = lambda { |memo| memo }

        [each || default_each, post || default_post]
      end

      def extract_matchers(match, nonmatch)
        match_lambda = lambda { |char| char =~ match }
        nonmatch_lambda = extract_nonmatch(match_lambda, nonmatch)

        [match_lambda, nonmatch_lambda]
      end

      def extract_nonmatch(match, nonmatch)
        if nonmatch
          lambda { |char| char =~ nonmatch }
        else
          lambda { |char| !match.call(char) }
        end
      end

      def extract_delimiters(delimiters)
        open, close = Array[delimiters].flatten[0..1]
        [open, close || open]
      end
    end
  end

  class Reader
    include ReaderDSL

    SyntaxError = Class.new(StandardError)

    class << self
      def readers
        @readers ||= []
      end
    end

    defreader :whitespace, match: /\s/,
      post: ->(memo) { nil }

    defreader :number, match: /\d/,
      post: ->(memo) { memo.join.to_i }

    defreader :symbol, match: /[a-zA-Z+\-*\/%_=<>]/, nonmatch: /[\s"()]/,
      post: ->(memo) { memo.join.to_sym }

    defreader :string, delimiters: '"',
      post: -> (memo) { memo.join }

    defreader :list, delimiters: ['(', ')'],
      each: -> (input, char) { input.ungetc(char); read_real(input) }

    def read(input)
      sexprs = []

      while !input.eof?
        result = read_real(input)
        sexprs << result unless result.nil?
      end
      sexprs
    end

    private

    def read_real(input)
      char = input.getc
      self.class.readers.each do |reader|
        if reader.begin_expr?(input, char)
          return reader.read(self, input)
        end
      end

      raise SyntaxError, 'unrecognized form'
    end
  end
end
