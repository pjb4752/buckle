module Buckle
  class FormPrinter
    def initialize(io = $stdout)
      @io = io
    end

    def printall(forms)
      forms.each do |form|
        print(form)
      end
    end

    def print(form)
      io.puts(recursive_to_s(form))
    end

    private

    attr_reader :io

    def recursive_to_s(form)
      case form
      when Array
        parenthesize(recursive_map(form))
      when String
        quote(form)
      when Fixnum, Symbol
        form.to_s
      end
    end

    def recursive_map(form)
      form.map { |f| recursive_to_s(f) }.join(' ')
    end

    def parenthesize(form)
      '(%s)' % form
    end

    def quote(form)
      '"%s"' % form
    end
  end
end
