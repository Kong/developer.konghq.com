# frozen_string_literal: true

require 'json'

module Jekyll
  class BrokenLinks < Generator
    priority :lowest

    class Page < Jekyll::Page
      def initialize(site, sources)
        @site = site
        @data = {}
        @content = JSON.pretty_generate(sources)

        process('sources_urls_mapping.json')
      end
    end

    def generate(site)
      return if ENV['JEKYLL_ENV'] == 'production'

      sources = Hash.new { |h, k| h[k] = [] }

      site.pages.each do |page|
        sources[file_path(page)] << page.url
      end

      site.documents.each do |doc|
        sources[file_path(doc)] << doc.url
      end

      site.pages << Page.new(site, sources)
    end

    def file_path(page)
      return page.relative_path if page.relative_path.start_with?('app')

      "app/#{page.relative_path}"
    end
  end
end
