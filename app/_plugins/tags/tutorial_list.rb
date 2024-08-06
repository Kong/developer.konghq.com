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
      config = keys.reduce(context) { |c, key| c[key] }.first

      tutorials = @site.collections['tutorials'].docs.select do |t|
        t.data['tags'].include?(config['tag']) &&
          (!config.key?('product') || t.data['products'].include?(config['product']))
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
