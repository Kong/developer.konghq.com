# frozen_string_literal: true

module Jekyll
  class Raise < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param
    end

    def render(context)
      message = Liquid::Template.parse(@param, { line_numbers: true }).render(context)
      raise "#{message} via #{context.registers[:page]['path']}"
    end
  end
end

Liquid::Template.register_tag('raise', Jekyll::Raise)
