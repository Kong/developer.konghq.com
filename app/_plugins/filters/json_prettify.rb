# frozen_string_literal: true

require 'json'

module Jekyll
  module JSONPrettifyFilter
    def json_prettify(input, last_line_spacing = nil)
      output = JSON.pretty_generate(input)
      if last_line_spacing
        # Add spacing to the last line if specified
        output_lines = output.split("\n")
        output_lines[-1] = ' ' * last_line_spacing.to_i + output_lines[-1]
        output_lines.join("\n")
      else
        output  # Return the prettified JSON without additional spacing
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::JSONPrettifyFilter)
