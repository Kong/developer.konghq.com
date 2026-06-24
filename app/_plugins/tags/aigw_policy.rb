# frozen_string_literal: true

require_relative '../monkey_patch'

module Jekyll
  class RenderAIGatewayPolicy < Liquid::Tag
    def initialize(tag_name, param, tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      @site    = context.registers[:site]
      @page    = @context.environments.first['page']
      @config = @param.split('.').reduce(context) { |c, key| c[key] } || @param
      @slug = @config.is_a?(Hash) ? @config['slug'] : @config

      policy = @site.data['ai_gateway_policies'][@slug]

      unless policy
        raise ArgumentError,
              "Error rendering {% aigw_policy %} on page: #{@page['path']}. The policy `#{@slug}` doesn't exist."
      end

      return '' if policy.data['published'] == false

      context.stack do
        context['policy'] = policy
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      if @page['output_format'] == 'markdown'
        File.read(File.expand_path('app/_includes/components/aigw_policy.md'))
      else
        File.read(File.expand_path('app/_includes/components/aigw_policy.html'))
      end
    end
  end
end

Liquid::Template.register_tag('aigw_policy', Jekyll::RenderAIGatewayPolicy)
