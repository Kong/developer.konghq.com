# frozen_string_literal: true

require 'json'

module Jekyll
  class EventGatewayConf < Liquid::Tag # rubocop:disable Style/Documentation
    def render(context)
      @context = context
      @site = context.registers[:site]
      @page = context.environments.first['page']

      context.stack do
        context['schema'] = @site.data.dig('event-gateway-bootstrap-schema', release(@site, @page).gsub('.', ''))
        Liquid::Template.parse(template).render(context)
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

    def template
      @template ||= if @page['output_format'] == 'markdown'
                      File.read(File.expand_path('app/_includes/components/event_gateway_conf.md'))
                    else
                      File.read(File.expand_path('app/_includes/components/event_gateway_conf.html'))
                    end
    end
  end
end

Liquid::Template.register_tag('event_gateway_conf', Jekyll::EventGatewayConf)
