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
        sources["app/#{page.relative_path}"] << page.url
      end

      site.documents.each do |doc|
        sources["app/#{doc.relative_path}"] << doc.url
      end

      site.pages << Page.new(site, sources)
    end
  end
end
