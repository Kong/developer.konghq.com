# frozen_string_literal: true

require_relative '../../lib/site_accessor'
require_relative 'sources/security_advisories'

module Jekyll
  module Feeds
    # Builds one RSS page per entry in app/_data/feeds.yml.
    class Generator
      include Jekyll::SiteAccessor

      # Maps the `source` value in feeds.yml to a class that responds to `.items(site)`.
      SOURCES = {
        'security_advisories' => Sources::SecurityAdvisories
      }.freeze

      def self.run(site)
        new(site).run
      end

      def initialize(site)
        @site = site
      end

      def run
        (@site.data['feeds'] || {}).each do |name, config|
          @site.pages << build_page(name, config)
        end
      end

      private

      attr_reader :site

      def build_page(name, config)
        PageWithoutAFile.new(site, site.source, 'feeds', "#{name}.xml").tap do |page|
          page.data['llm'] = false
          page.data['layout'] = nil
          page.data['feed'] = feed_data(name, config)
          page.content = '{% include feeds/rss.xml %}'
        end
      end

      def feed_data(name, config)
        items = source_for(name, config['source']).items(site)
        config.merge('name' => name, 'items' => items)
      end

      def source_for(name, source)
        SOURCES.fetch(source) do
          raise ArgumentError,
                "Feed '#{name}' in app/_data/feeds.yml has unknown source '#{source}'. " \
                "Known sources: #{SOURCES.keys.join(', ')}"
        end
      end
    end
  end
end
