# frozen_string_literal: true

module Jekyll
  module APIPages
    class Product
      attr_reader :site, :file, :product

      def initialize(product:, file:, site:, frontmatter:)
        @product = product
        @file = file.gsub("#{site.source}/", '')
        @site = site
        @frontmatter = frontmatter
      end

      def generate_pages!
        product['versions'].map do |version|
          site.pages << Page.new(product:, version:, file:, site:).to_jekyll_page
        end
        site.pages << APIPages::Canonical.new(product:, version: latest_version, file:, site:).to_jekyll_page
      end

      def latest_version
        @latest_version ||= @product['latestVersion']
      end
    end
  end
end
