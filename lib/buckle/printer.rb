module Buckle
  class Printer
    def initialize(io = $stdout)
      @io = io
    end

    def printall(forms)
      forms.value.each do |form|
        print(form)
      end
    end

    def print(form)
      io.puts(form.to_s)
    end

    private

    attr_reader :io

  end
end
