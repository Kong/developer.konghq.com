# frozen_string_literal: true

module Jekyll
  module APIPages
    class Page
      attr_reader :product, :version

      def initialize(product:, version:, file:, site:)
        @product = product
        @version = version
        @file = file
        @site = site
      end

      def to_jekyll_page
        CustomJekyllPage.new(site: @site, page: self)
      end

      def dir
        @dir ||= "#{base_url}#{version_segment}/"
      end

      def relative_path
        @relative_path ||= @file
      end

      def content
        @content ||= ''
      end

      def url
        @url || dir
      end

      def data
        {
          'title' => @product['title'],
          'api_spec' => api_spec,
          'version' => @version.slice('id', 'name'),
          'description' => @product['description'],
          'layout' => 'api/spec',
          'content_type' => 'reference',
          'canonical_url' => base_url,
          'seo_noindex' => true
        }
      end

      private

      def api_spec
        @api_spec ||= Drops::OAS::APISpec.new(product:, version:)
      end

      def base_url
        @base_url ||= @file
                      .gsub('_index.md', '')
                      .gsub('_api', '/api')
      end

      def version_segment
        @version_segment ||= @version.fetch('name')
      end
    end
  end
end
