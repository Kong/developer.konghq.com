# frozen_string_literal: true

module IndentFilter
  def indent(input, spaces)
    input
      .gsub("\n</code>", '</code>')
      .split("\n")
      .map { |l| l.prepend(' ' * spaces.to_i) }
      .join("\n")
  end
end

Liquid::Template.register_filter(IndentFilter)
