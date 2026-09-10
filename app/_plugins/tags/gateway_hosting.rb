# frozen_string_literal: true

require_relative '../monkey_patch'
require_relative '../component_templates'

module Jekyll
  class RenderGatewayHosting < Liquid::Tag
    def initialize(tag_name, param, tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site    = context.registers[:site]
      @page    = @context.environments.first['page']
      @config = @param.split('.').reduce(context) { |c, key| c[key] } || @param
      slug = @config.is_a?(Hash) ? @config['name'] : @config

      gateway_hosting = @site.data['gateway_hosting'][slug]

      context.stack do
        context['heading_level'] = Jekyll::ClosestHeading.new(@page, @line_number, context).level
        context['gateway_hosting'] = gateway_hosting
        ComponentTemplates.fetch('gateway_hosting', @page['output_format']).render(context)
      end
    end
  end
end

Liquid::Template.register_tag('gateway_hosting', Jekyll::RenderGatewayHosting)
