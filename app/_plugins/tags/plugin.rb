# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  class RenderPlugin < Liquid::Tag
    def initialize(tag_name, param, tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site    = context.registers[:site]
      @page    = @context.environments.first['page']
      @config = @param.split('.').reduce(context) { |c, key| c[key] } || @param
      @plugin_slug = @config.is_a?(Hash) ? @config['slug'] : @config

      plugin = @site.data['kong_plugins'][@plugin_slug]

      unless plugin
        raise ArgumentError,
              "Error rendering {% plugin %} on page: #{@page['path']}. The plugin `#{@plugin_slug}` doesn't exist."
      end

      return '' if plugin.data['published'] == false

      context.stack do
        context['plugin'] = plugin
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/plugin.md'))
      else
        File.read(File.expand_path('app/_includes/components/plugin.html'))
      end
    end
  end
end

Liquid::Template.register_tag('plugin', Jekyll::RenderPlugin)
