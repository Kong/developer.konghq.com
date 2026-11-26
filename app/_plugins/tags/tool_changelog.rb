# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderToolChangelog < Liquid::Tag # rubocop:disable Style/Documentation
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      site = context.registers[:site]
      tool = @param[/tool="([^"]+)"/, 1]

      raise ArgumentError, 'Missing required parameter `tool` for {% tool_changelog %}' if tool.nil?

      changelog = Drops::ToolChangelog.new(site:, tool:)

      context.stack do
        context['changelog'] = changelog
        ComponentTemplates.fetch('tool_changelog', @context.environments.first['page']['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('tool_changelog', Jekyll::RenderToolChangelog)
