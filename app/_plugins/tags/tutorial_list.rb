# frozen_string_literal: true

module Jekyll
  class RenderTutorialList < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
      if @param.nil? || @param.empty?
        raise ArgumentError, "Missing param for {% tutorial_list %}"
      end
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      keys = @param.split('.')
      config = keys.reduce(context) { |c, key| c[key] }

      quantity = config.fetch('quantity', 10)

      tutorials = @site.collections['tutorials'].docs.inject([]) do |result, t|
        match = (!config.key?('tags') || t.data.fetch('tags', []).intersect?(config['tags'])) &&
          (!config.key?('products') || t.data.fetch('products', []).intersect?(config['products']))

        result << t if match
        break result if result.size == quantity

        result
      end

      context.stack do
        context['tutorials'] = tutorials
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/tutorial_list.html'))
    end
  end
end

Liquid::Template.register_tag('tutorial_list', Jekyll::RenderTutorialList)
