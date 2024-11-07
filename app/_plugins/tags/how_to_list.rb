# frozen_string_literal: true

module Jekyll
  class RenderHowToList < Liquid::Tag
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
      if @param.nil? || @param.empty?
        raise ArgumentError, "Missing param for {% how_to_list %}"
      end
    end

    def render(context)
      @context = context
      @site = context.registers[:site]
      keys = @param.split('.')
      config = keys.reduce(context) { |c, key| c[key] }

      quantity = config.fetch('quantity', 10)

      how_tos = @site.collections['how-tos'].docs.inject([]) do |result, t|
        match = (!config.key?('tags') || t.data.fetch('tags', []).intersect?(config['tags'])) &&
          (!config.key?('products') || t.data.fetch('products', []).intersect?(config['products'])) &&
          (!config.key?('tools') || t.data.fetch('tools', []).intersect?(config['tools']))

        result << t if match
        break result if result.size == quantity

        result
      end

      if how_tos.empty? && !config.fetch('allow_empty', false)
        raise "No how-tos found for #{@context['page']['path']} - #{config}"
      end

      context.stack do
        context['how_tos'] = how_tos
        context['config'] = config
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/how_to_list.html'))
    end
  end
end

Liquid::Template.register_tag('how_to_list', Jekyll::RenderHowToList)
