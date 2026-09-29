# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderGatewayChangelog < Liquid::Tag # rubocop:disable Style/Documentation
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @page = @context.environments.first['page']
      site = context.registers[:site]
      product = @page['products']&.first || 'gateway'
      changelog = Drops::GatewayChangelog.new(site:, product:)

      context.stack do
        context['changelog'] = changelog
        ComponentTemplates.fetch('gateway_changelog', @page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('gateway_changelog', Jekyll::RenderGatewayChangelog)
