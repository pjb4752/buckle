module Buckle
  class Printer
    def initialize(io = $stdout, err = $stderr)
      @io = io
      @err = err
    end

    def printall(forms)
      forms.value.each do |form|
        print(form)
      end
    end

    def print(form)
      io.puts(form.to_s)
    end

    def error(message)
      err.puts(message)
    end

    private

    attr_reader :io, :err

  end
end
