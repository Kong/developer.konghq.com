# frozen_string_literal: true

require_relative '../../lib/major_version_resolver'

module Jekyll
  module Drops
    class DataPrereqs
      def initialize(product:, major:, product_data:)
        @product = product
        @major = major
        @product_data = product_data
      end

      def versioned_include
        unless entities_product_include_path.include?(versioned_key)
          raise "No app/_includes/prereqs/entities/#{versioned_key} file found"
        end

        "#{ENTITIES_INCLUDES_PATH}#{versioned_key}.md"
      end

      def versioned_key
        @versioned_key ||= if @major
                             url_segment = major_url_segement
                             "#{@product}/#{url_segment}"
                           else
                             @product
                           end
      end

      def major_url_segement
        MajorVersionResolver.process(
          product_data: @product_data,
          major: @major
        )
      end

      def entities_product_include_path
        @entities_product_include_path ||= ENTITIES_INCLUDES.map do |path|
          path.sub("app/_includes/#{ENTITIES_INCLUDES_PATH}", '').sub('.md', '')
        end.to_set
      end
    end
  end
end
