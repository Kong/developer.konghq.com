# frozen_string_literal: true

require 'yaml'

module Jekyll
  module APIPages
    class Product
      attr_reader :site, :file, :product, :frontmatter

      def initialize(product:, file:, site:, frontmatter:)
        @product = product
        @file = file.gsub("#{site.source}/", '')
        @site = site
        @frontmatter = frontmatter
      end

      def generate_pages! # rubocop:disable Metrics/AbcSize
        versions.map do |version|
          page = Page.new(product:, version:, file:, site:, frontmatter:).to_jekyll_page
          site.pages << page
          site.data['ssg_api_pages'] << page if page.data['canonical?']

          site.pages << ErrorPage.new(product:, version:, file:, site:, errors:).to_jekyll_page if errors
        end
      end

      private

      def errors
        @errors ||= begin
          return [] unless api_spec_path

          oas = YAML.load_file(api_spec_path)
          raise ArgumentError, "Could not load #{api_spec_path}" unless oas

          oas['x-errors']
        end
      end

      def api_spec_path
        @api_spec_path ||= begin
          return nil unless @frontmatter.fetch('insomnia_link', nil)

          spec_file = CGI.unescape(@frontmatter.fetch('insomnia_link')).split('&uri=')[1].gsub(
            'https://raw.githubusercontent.com/Kong/developer.konghq.com/main/', ''
          )
          File.join(@site.source, '..', spec_file)
        end
      end

      def versions
        @versions ||= product.fetch('versions', []).map do |v|
          Drops::OAS::Version.new(v)
        end
      end
    end
  end
end
