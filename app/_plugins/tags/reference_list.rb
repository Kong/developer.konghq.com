# frozen_string_literal: true

module Jekyll
  class RenderReferenceListt < Liquid::Tag # rubocop:disable Style/Documentation
    def initialize(tag_name, param, _tokens)
      super

      @param = param.strip
      return unless @param.nil? || @param.empty?

      raise ArgumentError, 'Missing param for {% reference_list %}'
    end

    def render(context) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
      @context = context
      @site = context.registers[:site]
      keys = @param.split('.')
      config = keys.reduce(context) { |c, key| c[key] }

      quantity = config.fetch('quantity', 10)

      references = @site.pages.select { |p| p.data['content_type'] == 'reference' }.each_with_object([]) do |p, result|
        next if p.data['auto_generated']

        match = (!config.key?('tags') || p.data.fetch('tags', []).intersect?(config['tags'])) &&
                (!config.key?('products') || p.data.fetch('products', []).intersect?(config['products'])) &&
                (!config.key?('tools') || p.data.fetch('tools', []).intersect?(config['tools']))

        result << p if match
        break result if result.size == quantity
      end

      if references.empty? && !config.fetch('allow_empty', false)
        raise "No references found for #{@context['page']['path']} - #{config}"
      end

      context.stack do
        context['references'] = references
        context['view_more_url'] = view_more_url(config)
        context['config'] = config
        Liquid::Template.parse(template).render(context)
      end
    end

    private

    def template
      @template ||= File.read(File.expand_path('app/_includes/components/reference_list.html'))
    end

    def view_more_url(config)
      query_string = URI.encode_www_form(config.slice('products', 'tags', 'tools').merge(content_type: 'reference'))
      url_segment = '/search'
      query_string.empty? ? url_segment : "#{url_segment}?#{query_string}"
    end
  end
end

Liquid::Template.register_tag('reference_list', Jekyll::RenderReferenceListt)
