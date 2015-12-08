module Buckle
  module Printing
    def self.dump(forms, io = $stdout)
      io.puts(recursive_dump(forms))
    end

    private

    def self.recursive_dump(forms)
      case forms
      when Array
        parenthesize(recursive_map(forms))
      when Fixnum, String, Symbol
        forms.to_s
      end
    end

    def self.recursive_map(forms)
      forms.map { |f| recursive_dump(f) }.join(' ')
    end

    def self.parenthesize(forms)
      '(%s)' % forms
    end
  end
end
