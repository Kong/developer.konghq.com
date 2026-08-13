# frozen_string_literal: true

require_relative '../../lib/major_version_resolver'

module Jekyll
  module Drops
    class ProductIncludePrereqs
      PRODUCT_INCLUDES_PATH = 'prereqs/products/'
      PRODUCT_INCLUDES = Dir.glob("app/_includes/#{PRODUCT_INCLUDES_PATH}**/*.md").freeze

      def initialize(products:, major_version:, products_data:)
        @products = products
        @major_version = major_version
        @products_data = products_data
      end

      def products_include_map
        @products_include_map ||= @products.each_with_object({}) do |product, map|
          next if skip_product?(product)

          include_file = versioned_include(product)

          map[product] = include_file if include_file
        end
      end

      def exist?(product_include)
        product_include_paths.include?(product_include)
      end

      private

      def product_include_paths
        @product_include_paths ||= PRODUCT_INCLUDES.map do |path|
          path.sub("app/_includes/#{PRODUCT_INCLUDES_PATH}", '').sub('.md', '')
        end.to_set
      end

      def versioned_include(product)
        file = product
        file = "#{product}/#{major_url_segement_for(product)}" if major_version_for(product)
        return nil unless exist?(file)

        "#{PRODUCT_INCLUDES_PATH}#{file}.md"
      end

      def skip_product?(product)
        return true if product == 'gateway'
        return true if product == 'ai-gateway' && major_version_for(product) == 1

        false
      end

      def major_version_for(product)
        @major_version&.dig(product)
      end

      def major_url_segement_for(product)
        MajorVersionResolver.process(
          product_data: @products_data[product],
          major: major_version_for(product)
        )
      end
    end
  end
end
