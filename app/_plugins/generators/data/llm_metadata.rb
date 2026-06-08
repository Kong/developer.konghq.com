# frozen_string_literal: true

require 'yaml'
require_relative 'title/base'

module Jekyll
  module Data
    class LlmMetadata # rubocop:disable Style/Documentation
      attr_reader :site, :page

      def initialize(site:, page:)
        @site = site
        @page = page
        @page.data['llm_metadata'] ||= {}
      end

      def process
        return if @page.url.start_with?('/assets/')
        return if @page.data['layout'] && @page.data['layout'] == 'none'
        return if @site.config.dig('sitemap', 'exclude').include?(@page.url)

        set_metadata
      end

      def set_metadata
        @page.data['llm_frontmatter'] = frontmatter
      end

      def frontmatter
        data = {
          'title' => @page.data['llm_title'],
          'description' => @page.data['description'],
          'url' => @page.url,
          'content_type' => @page.data['content_type'],
          'third_party' => @page.data['third_party'],
          'premium_partner' => @page.data['premium_partner'],
          'ai_gateway_enterprise' => @page.data['ai_gateway_enterprise'],
          'min_version' => @page.data['min_version'],
          'tier' => @page.data['tier'],
          'tiers' => resolve_tiers(@page.data['tiers']),
          'products' => resolve_names(@page.data['products'], 'products'),
          'tools' => resolve_names(@page.data['tools'], 'tools'),
          'beta' => @page.data['beta']
        }
        data['tags'] = @page.data['tags'] if @page.data.fetch('tags', []).any?
        data['canonical'] = @page.data['canonical?'] unless @page.data['canonical?'].nil?
        data['works_on']  = @page.data['works_on'] if @page.data.fetch('works_on', []).any?

        data.merge!(plugin_metadata) if plugin_metadata.any?
        data.merge!(skill_metadata) if skill_metadata.any?
        YAML.dump(data.compact)
      end

      def resolve_names(slugs, data_key)
        return if Array(slugs).empty?

        Array(slugs).map { |slug| @site.data.dig(data_key, slug, 'name') || slug }
      end

      def resolve_tiers(tiers)
        return if tiers.nil? || tiers.empty?

        tiers.each_with_object({}) do |(product, tier_name), out|
          name = @site.data.dig('products', product, 'name') || product
          out[name] = @site.data.dig('products', product, 'tiers', tier_name, 'text') || tier_name
        end
      end

      def plugin_metadata
        if @page.data['plugin?'] && @page.data['overview?']
          {
            'topologies' => @page.data['topologies'],
            'publisher' => @page.data['publisher'],
            'compatible_protocols' => @page.data['compatible_protocols'],
            'categories' => @page.data['categories']
          }
        else
          {}
        end
      end

      def skill_metadata
        return {} unless @page.data['content_type'] == 'skill'

        { 'source' => @page.data['source_url'], 'owning_plugin' => @page.data['plugin_source_url'] }
      end
    end
  end
end
