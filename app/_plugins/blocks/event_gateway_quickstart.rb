# frozen_string_literal: true

require 'yaml'
require_relative '../drops/event_gateway_quickstart'
require_relative '../component_templates'

module Jekyll
  class EventGatewayQuickstart < Liquid::Block # rubocop:disable Style/Documentation
    # An empty (or env-less) block body is whitespace-only, which Liquid treats as a "blank"
    # block and silently discards the rendered output for. This block always has output.
    def blank?
      false
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      @context = context
      @page = context.environments.first['page']
      @format = @page['output_format'] || 'html'

      contents = super
      config = YAML.load(contents) || {}
      drop = Drops::EventGatewayQuickstart.new(yaml: config)

      context.stack do
        context['config'] = drop
        ComponentTemplates.fetch(
          'how-tos/event-gateway-quickstart/index', @format, base: 'app/_includes'
        ).render(context)
      end
    rescue Psych::SyntaxError => e
      message = <<~STRING
        On `#{@page['path']}`, the following {% event_gateway_quickstart %} block contains a malformed yaml:
        #{contents.strip.split("\n").each_with_index.map { |l, i| "#{i}: #{l}" }.join("\n")}
        #{e.message}
      STRING
      raise ArgumentError, message
    end
  end
end

Liquid::Template.register_tag('event_gateway_quickstart', Jekyll::EventGatewayQuickstart)
