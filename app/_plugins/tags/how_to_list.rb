# frozen_string_literal: true

require 'uri'

module Jekyll
  class RenderHowToList < Liquid::Tag # rubocop:disable Style/Documentation
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
      return unless @param.nil? || @param.empty?

      raise ArgumentError, 'Missing param for {% how_to_list %}'
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      @context = context
      @site = context.registers[:site]
      keys = @param.split('.')
      config = keys.reduce(context) { |c, key| c[key] }

      quantity = config.fetch('quantity', 10)

      how_tos = @site.collections['how-tos'].docs.each_with_object([]) do |t, result|
        match = (!config.key?('tags') || t.data.fetch('tags', []).intersect?(config['tags'])) &&
                (!config.key?('products') || t.data.fetch('products', []).intersect?(config['products'])) &&
                (!config.key?('works_on') || t.data.fetch('works_on', []).intersect?(config['works_on'])) &&
                (!config.key?('tools') || t.data.fetch('tools', []).intersect?(config['tools'])) &&
                (!config.key?('plugins') || t.data.fetch('plugins', []).intersect?(config['plugins']))

        result << t if match
        break result if result.size == quantity
      end

      if how_tos.empty? && !config.fetch('allow_empty', false) && ENV['KONG_PRODUCTS'].nil?
        raise "No how-tos found for #{@context['page']['path']} - #{config}"
      end

      context.stack do
        context['how_tos'] = how_tos
        context['view_more_url'] = view_more_url(config)
        context['config'] = config
        Liquid::Template.parse(template, { line_numbers: true }).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/how_to_list.html'))
    end

    def view_more_url(config)
      query_string = URI.encode_www_form(config.slice('products', 'tags', 'tools', 'works_on'))
      url_segment = '/how-to'
      query_string.empty? ? url_segment : "#{url_segment}?#{query_string}"
    end
  end
end

Liquid::Template.register_tag('how_to_list', Jekyll::RenderHowToList)
