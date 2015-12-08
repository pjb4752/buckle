module Buckle
  module Readable
    SyntaxError = Class.new(StandardError)

    def read(input)
      sexprs = []

      while !input.eos?
        result = read_real(input)
        sexprs << result unless result.nil?
      end
      sexprs
    end

    private

    def read_real(input)
      readers.each do |reader|
        if reader.begin_expr?(input)
          return reader.read(input)
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
      extend Buckle::Readable

      attr_reader :name, :post, :recurse

      def initialize(name, post, recurse)
        @name = name
        @post = post
        @recurse = recurse
      end

      def read(input)
        memo = []
        loop do
          char = input.first
          break if yield char

          if recurse
            result = self.class.send(:read_real, input)
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

      def read(input)
        super(input) do |char|
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

      def read(input)
        super(input) do |char|
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
    extend Readable

    defreader :whitespace, match: /\s/,
      post: ->(memo) { nil }

    defreader :number, match: /\d/,
      post: ->(memo) { memo.join.to_i }

    defreader :symbol, match: /[a-zA-Z+\-*\/%_=<>]/, nonmatch: /[\s"()]/,
      post: ->(memo) { memo.join.to_sym }

    defreader :string, delimiters: '"',
      post: -> (memo) { memo.join }

    defreader :list, delimiters: ['(', ')'], recurse: true

  end
end
