# frozen_string_literal: true

module Jekyll
  class RenderPluginConfigExamples < Liquid::Tag
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      plugin_config_examples = Drops::PluginConfigExamples.new(page: @page, site: @site)

      context.stack do
        context['plugin_examples'] = plugin_config_examples.examples
        Liquid::Template
          .parse(File.read('app/_includes/components/plugin_config_examples.html'))
          .render(context)
      end
    end
  end
end

Liquid::Template.register_tag('plugin_config_examples', Jekyll::RenderPluginConfigExamples)
