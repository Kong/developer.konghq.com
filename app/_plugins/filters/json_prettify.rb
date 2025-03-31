# frozen_string_literal: true

require 'json'

module Jekyll
  module JSONPrettifyFilter
    def json_prettify(input, indent_by = nil)
      output = JSON.pretty_generate(input)
      if indent_by
        output_lines = output.split("\n")
        indent_spaces = ' ' * indent_by.to_i
        output_lines.map! { |line| "#{indent_spaces}#{line}" }
        output = output_lines.join("\n")
      else
        output  # Return the prettified JSON without additional spacing
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::JSONPrettifyFilter)
