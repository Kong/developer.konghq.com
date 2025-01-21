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
          @entries << entry(page) if page['canonical?']
        end

        @site.documents.map do |page|
          @entries << entry(page) if page['canonical?']
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
    end
  end
end
