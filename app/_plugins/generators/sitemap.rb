# frozen_string_literal: true

module Jekyll
  class SitemapGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    priority :lowest

    def generate(site)
      return if ENV['JEKYLL_ENV'] == 'development'

      site.data['sitemap_pages'] = Sitemap::Generator.run(site)
    end
  end
end
