require 'buckle/types/vector'

module Buckle
  module Readable
    SyntaxError = Class.new(StandardError)

    def read(input)
      sexprs = Types::List.new

      while !input.eos?
        result = try_read(self.class.readers, input)
        sexprs.value << result unless result.nil?
      end
      sexprs
    end

    private

    def try_read(readers, input)

      readers.each do |reader|
        if reader.begin_expr?(input)
          continuation = lambda do |new_input|
            try_read(readers, new_input)
          end

          return reader.read(input, continuation)
        end
      end

      raise SyntaxError, 'unrecognized form'
    end
  end

  module ReaderDSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    InvalidReaderError = Class.new(StandardError)

    class << self
      def readers
        @readers ||= []
      end
    end

    class FormReader

      attr_reader :name, :post, :recurse

      def initialize(name, post, recurse)
        @name = name
        @post = post
        @recurse = recurse
      end

      def read(input, continuation)
        memo = []
        loop do
          char = input.first
          break if yield char

          if recurse
            result = continuation.call(input)
          else
            result = char
            input.next
          end
          memo << result unless result.nil?
        end
        post.call(memo)
      end

      def self.readers
        ReaderDSL.readers
      end
    end

    class MatchReader < FormReader
      attr_reader :match, :nonmatch

      def initialize(name, match, nonmatch, each, post)
        super(name, each, post)

        @match = match
        @nonmatch = nonmatch
      end

      def begin_expr?(input)
        match.call(input.first)
      end

      def read(input, continuation)
        super(input, continuation) do |char|
          char.nil? || nonmatch_handled?(char)
        end
      end

      private

      def nonmatch_handled?(char)
        nonmatch.call(char)
      end
    end

    class DelimitedReader < FormReader
      attr_reader :open, :close

      def initialize(name, open, close, each, post)
        super(name, each, post)

        @open = open
        @close = close
      end

      def begin_expr?(input)
        test_and_eat(input, open)
      end

      def read(input, continuation)
        super(input, continuation) do |char|
          raise_eos_error if char.nil?
          end_expr?(input)
        end
      end

      private

      def end_expr?(input)
        test_and_eat(input, close)
      end

      def test_and_eat(input, expr)
        if input.first == expr
          input.next # eat delimiter
          true
        else
          false
        end
      end

      def raise_eos_error
        raise SyntaxError, 'unexpected end of stream'
      end
    end

    module ClassMethods
      def readers
        ReaderDSL.readers
      end

      def defreader(name, match: nil, nonmatch: nil, delimiters: nil,
                    post: nil, recurse: false)
        if match.nil? && (delimiters.nil? || delimiters.empty?)
          raise InvalidReaderError, 'must specify one of match or delimiters'
        end

        each, post = extract_processors(each, post)
        if match
          match_l, nonmatch_l = extract_matchers(match, nonmatch)
          readers << MatchReader.new(name, match_l, nonmatch_l, post, recurse)
        else
          open, close = extract_delimiters(delimiters)
          readers << DelimitedReader.new(name, open, close, post, recurse)
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
    include Readable

    defreader :whitespace, match: /\s/,
      post: ->(memo) { nil }

    defreader :number, match: /\d/,
      post: ->(memo) { Types::Number.from_chars(memo) }

    defreader :symbol, match: /[a-zA-Z+\-*\/%_=<>]/, nonmatch: /[\s"()\[\]]/,
      post: ->(memo) { Types::Symbol.from_chars(memo) }

    defreader :keyword, match: /[:]/, nonmatch: /[\s"()\[\]]/,
      post: ->(memo) { Types::Keyword.from_chars(memo) }

    defreader :string, delimiters: '"',
      post: ->(memo) { Types::String.from_chars(memo) }

    defreader :list, delimiters: ['(', ')'], recurse: true,
      post: ->(memo) { Types::List.from_array(memo) }

    defreader :vector, delimiters: ['[', ']'], recurse: true,
      post: ->(memo) { Types::Vector.from_array(memo) }

    defreader :map, delimiters: ['{', '}'], recurse: true,
      post: ->(memo) { Types::Map.from_array(memo) }

  end
end
