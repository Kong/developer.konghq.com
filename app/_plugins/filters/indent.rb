# frozen_string_literal: true

module IndentFilter
  def indent(input, spaces=3)
    input
      .to_s
      .gsub("\n</code>", '</code>')
      .split("\n")
      .map { |l| l.prepend(' ' * spaces.to_i) }
      .join("\n")
  end
end

Liquid::Template.register_filter(IndentFilter)
