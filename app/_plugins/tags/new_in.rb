# frozen_string_literal: true

module Jekyll
  class RenderNewIn < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site = context.registers[:site]

      raise ArgumentError, 'Missing required parameter `version` for {% new_in %} ' unless @param

      context.stack do
        context['version'] = @param
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/new_in.html'))
    end
  end
end

Liquid::Template.register_tag('new_in', Jekyll::RenderNewIn)
