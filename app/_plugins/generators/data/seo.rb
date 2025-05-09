# frozen_string_literal: true

module Jekyll
  module Data
    class Seo # rubocop:disable Style/Documentation
      def initialize(site:, page:)
        @site = site
        @page = page
      end

      def process
        # TODO: consider redirects
        return if @page.data['canonical?']
        return if @page.url.start_with?('/assets/mesh/')

        if !canonical?
          @page.data['seo_noindex'] = true
        else
          @page.data.merge!('canonical?' => true, 'canonical_url' => @page.url)
        end
      end

      def canonical?
        case @page.data['content_type']
        when 'how_to', 'landing_page', 'concept', 'plugin'
          true
        when 'reference', 'api'
          # Reference pages have canonical? set already (in Versioner)
          @page.data['canonical?']
        else
          exclusions = @site.config.dig('sitemap', 'exclude')
          !exclusions.include?(@page.url)
        end
      end
    end
  end
end
