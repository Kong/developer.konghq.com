# frozen_string_literal: true

module Jekyll
  class RenderGatewayChangelog < Liquid::Tag # rubocop:disable Style/Documentation
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
    end

    def render(context)
      @context = context
      site = context.registers[:site]
      changelog = Drops::GatewayChangelog.new(site:)

      context.stack do
        context['changelog'] = changelog
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/gateway_changelog.html'))
    end
  end
end

Liquid::Template.register_tag('gateway_changelog', Jekyll::RenderGatewayChangelog)
