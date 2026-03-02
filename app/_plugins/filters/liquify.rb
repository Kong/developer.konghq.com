# frozen_string_literal: true

module Jekyll
  module LiquifyFilter
    def liquify(input)
      if input.is_a? String
        Liquid::Template.parse(input, { line_numbers: true }).render(
          @context.environments.first,
          registers: @context.registers
        )
      else
        input
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::LiquifyFilter)
