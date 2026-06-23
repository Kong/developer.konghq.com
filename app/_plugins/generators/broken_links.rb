# frozen_string_literal: true

require 'json'

module Jekyll
  class BrokenLinks < Generator
    priority :lowest

    def generate(site)
      return if ENV['JEKYLL_ENV'] == 'production'

      sources = Hash.new { |h, k| h[k] = [] }

      site.pages.each do |page|
        next if page.url.start_with?('/assets/')

        sources[file_path(page)] << page.url
      end

      site.documents.each do |doc|
        sources[file_path(doc)] << doc.url
      end

      site.pages << build_page(site, sources)
    end

    def file_path(page)
      return page.relative_path if page.relative_path.start_with?('app')

      "app/#{page.relative_path}"
    end

    def build_page(site, sources)
      PageWithoutAFile.new(site, __dir__, '', 'sources_urls_mapping.json').tap do |page|
        page.data['layout'] = nil
        page.content = JSON.pretty_generate(sources)
      end
    end
  end
end
