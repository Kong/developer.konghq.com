# frozen_string_literal: true

require 'json'
require_relative '../monkey_patch'
require_relative '../utils/json_schema_deref'
require_relative '../component_templates'

module Jekyll
  class EventGatewayConf < Liquid::Tag # rubocop:disable Style/Documentation
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      context.stack do
        raw = @site.data.dig('event-gateway-bootstrap-schema', release(@site, @page).gsub('.', ''))
        context['schema'] = Jekyll::Utils::JsonSchemaDeref.new(raw).resolve
        ComponentTemplates.fetch('event_gateway_conf', @page['output_format']).render(context)
      end
    end

    def release(site, page)
      return latest_release(site) unless page['release']

      release = releases(site).detect { |r| r['release'] == page['release'].number }

      if release&.key?('label')
        latest_release(site)
      elsif release
        release['release']
      else
        latest_release(site)
      end
    end

    def latest_release(site)
      @latest_release ||= releases(site).detect { |r| r['latest'] }['release']
    end

    def releases(site)
      @releases ||= site.data.dig('products', 'event-gateway', 'releases')
    end
  end
end

Liquid::Template.register_tag('event_gateway_conf', Jekyll::EventGatewayConf)
