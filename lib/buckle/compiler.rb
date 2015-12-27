require 'buckle/text_stream'
require 'buckle/types/all'

module Buckle
  class Compiler

    def analyze(forms)
      values = forms.value.map do |form|
        analyze_form(form)
      end

      Types::Helpers.wrap_collections(values)
    end

    private

    def analyze_form(form)
      if form.number?
        analyze_number(form)
      elsif form.string?
        analyze_string(form)
      elsif form.keyword?
        analyze_keyword(form)
      elsif form.symbol?
        analyze_symbol(form)
      elsif form.list?
        analyze_list(form)
      elsif form.vector?
        analyze_vector(form)
      elsif form.map?
        analyze_map(form)
      else
        raise RuntimeError, 'nothing'
      end
    end

    def analyze_number(number)
      { num: number }
    end

    def analyze_string(string)
      { str: string }
    end

    def analyze_keyword(keyword)
      { key: keyword }
    end

    def analyze_symbol(symbol)
      { sym: symbol }
    end

    def analyze_list(list)
      {
        list: {
          children: list.value.map { |f| analyze_form(f) }
        }
      }
    end

    def analyze_vector(vector)
      {
        vector: {
          elements: vector.value.map { |f| analyze_form(f) }
        }
      }
    end

    def analyze_map(map)
      {
        map: {
          keys: map.value.keys.each { |f| analyze_form(f) },
          values: map.value.values.each { |f| analyze_form(f) }
        }
      }
    end
  end
end
