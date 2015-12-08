module Buckle
  class TextStream
    attr_reader :text

    def first
      text[pointer]
    end

    def next
      self.pointer += 1
      first
    end

    def eos?
      pointer >= text.length
    end

    def self.from_str(text)
      self.new(text)
    end

    def self.from_file(filename)
      File.open(filename, 'r') do |file|
        self.from_str(file.read)
      end
    end

    protected

    attr_accessor :pointer

    def initialize(text)
      @text = text
      @pointer = 0
    end
  end
end
