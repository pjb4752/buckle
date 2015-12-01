module Buckle
  module Printing

    def self.dump_forms(sexprs)
      forms = recursive_dump(sexprs)
      puts forms
    end

    private

    def self.recursive_dump(sexprs)
      case sexprs
      when Array
        forms = sexprs.map { |s| recursive_dump(s) }.join(' ')
        "(#{forms})"
      when Fixnum
        sexprs
      when String
        sexprs
      when Symbol
        sexprs.to_s
      end
    end
  end
end
