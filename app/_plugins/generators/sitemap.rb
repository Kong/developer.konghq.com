# frozen_string_literal: true

require_relative '../lib/ordered_generator'

module Jekyll
  class SitemapGenerator < OrderedGenerator # rubocop:disable Style/Documentation
    def generate(site)
      return if ENV['JEKYLL_ENV'] == 'development'

      site.data['sitemap_pages'] = Sitemap::Generator.run(site)
    end
  end
end
