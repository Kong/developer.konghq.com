# frozen_string_literal: true

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
        @page.data['llm_metadata']['products'] = products
        @page.data['llm_metadata']['tier'] = tier
        @page.data['llm_metadata']['tools'] = tools
      end

      def products
        @products ||= @page.data.fetch('products', []).map do |product|
          @site.data.dig('products', product, 'name')
        end
      end

      def tier
        return unless @page.data['tier']

        @tier ||= begin
          product = @page.data['products'].first

          @site.data.dig('products', product, 'tiers', @page.data['tier'], 'text')
        end
      end

      def tools
        return unless @page.data['tools']

        @tools ||= @page.data.fetch('tools', []).map do |tool|
          @site.data.dig('tools', tool, 'name')
        end
      end
    end
  end
end
