# frozen_string_literal: true

module Jekyll
  module Sitemap
    class Generator # rubocop:disable Style/Documentation
      def self.run(site)
        new(site).run
      end

      def initialize(site)
        @site = site
        @entries = []
      end

      def run
        @site.pages.map do |page|
          next if skip?(page)

          @entries << entry(page) if page['canonical?']
        end

        @site.documents.map do |page|
          next if skip?(page)

          @entries << entry(page) if page['canonical?'] && !page.data['skip_sitemap']
        end

        @entries.sort_by { |e| e['url'] }
      end

      def entry(page)
        {
          'url' => page.url,
          'changefreq' => 'weekly',
          'priority' => '1.0'
        }
      end

      def skip?(page)
        page.url.end_with?('.md') || page.url.start_with?('/.well-known/')
      end
    end
  end
end
