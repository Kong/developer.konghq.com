# frozen_string_literal: true

module Jekyll
  class SitemapGenerator < Jekyll::Generator # rubocop:disable Style/Documentation
    class Page < Jekyll::Page # rubocop:disable Style/Documentation
      def initialize(site, basename, domain) # rubocop:disable Lint/MissingSuper, Metrics/MethodLength
        @site = site
        @base = site.source
        @dir = '/sitemap-index/'
        @basename = basename
        @ext = '.xml'

        @content = ''

        @data = {
          'layout' => 'sitemap',
          'permalink' => "#{@dir}#{@basename}#{@ext}",
          'domain' => domain,
          'no_version' => true
        }
      end
    end

    priority :lowest

    def generate(site)
      return if ENV['JEKYLL_ENV'] == 'development'

      site.data['sitemap_pages'] = Sitemap::Generator.run(site)

      page = Page.new(site, 'default', site.config.dig('links', 'web'))

      site.pages << page
    end
  end
end
