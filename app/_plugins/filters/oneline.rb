# frozen_string_literal: true

module OnelineFilter
  def oneline(input)
    input.to_s.gsub(/\n/, ' ')
  end
end

Liquid::Template.register_filter(OnelineFilter)
