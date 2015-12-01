module Buckle
  module Reading
    SyntaxError = Class.new(StandardError)

    def self.read(input)
      sexprs = []

      while !input.eof?
        result = read_real(input)
        sexprs << result unless result.nil?
      end
      sexprs
    end

    private

    def self.read_real(input)
      next_char = input.getc

      case
      when whitespace?(next_char)
        read_whitespace(input)
      when digit?(next_char)
        input.ungetc(next_char) # return first char for reading
        read_number(input)
      when string_open?(next_char)
        read_string(input)
      when symbol_open?(next_char)
        input.ungetc(next_char) # return first char for reading
        read_symbol(input)
      when list_open?(next_char)
        read_list(input)
      else
        raise SyntaxError, 'unknown form'
      end
    end

    def self.whitespace?(char)
      char =~ /\s/
    end

    def self.read_whitespace(input)
      while !input.eof?
        char = input.getc
        if !whitespace?(char)
          input.ungetc(char)
          break
        end
      end
    end

    def self.digit?(char)
      char =~ /\d/
    end

    def self.read_number(input)
      digits = []
      while !input.eof?
        char = input.getc
        if digit?(char)
          digits << char
        else
          input.ungetc(char)
          break
        end
      end
      digits.join.to_i
    end

    def self.string_open?(char)
      char == '"'
    end
    class << self
      alias_method :string_close?, :string_open?
    end

    def self.read_string(input)
      chars = []
      loop do
        char = input.getc
        raise_syntax_error if char.nil?
        break if string_close?(char)
        chars << char
      end
      chars.join
    end

    def self.symbol_open?(char)
      char =~ /[a-zA-Z+\-*\/%_=<>]/
    end

    def self.symbol_close?(char)
      char =~ /[\s"()]/
    end

    def self.read_symbol(input)
      chars = []
      while !input.eof?
        char = input.getc
        break if symbol_close?(char)
        chars << char
      end
      chars.join.to_sym
    end

    def self.list_open?(char)
      char == '('
    end

    def self.list_close?(char)
      char == ')'
    end

    def self.read_list(input)
      forms = []
      loop do
        char = input.getc
        raise_syntax_error if char.nil?
        break if list_close?(char)
        input.ungetc(char)
        form = read_real(input)
        forms << form unless form.nil?
      end
      forms
    end

    def self.raise_syntax_error
      raise SyntaxError, 'unexpected end of stream'
    end
  end
end
