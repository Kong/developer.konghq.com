# frozen_string_literal: true

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
                             url_segment = @product_data['previous_major_url_segment']&.gsub('<major>', @major.to_s)
                             "#{@product}/#{url_segment}"
                           else
                             @product
                           end
      end

      def entities_product_include_path
        @entities_product_include_path ||= ENTITIES_INCLUDES.map do |path|
          path.sub("app/_includes/#{ENTITIES_INCLUDES_PATH}", '').sub('.md', '')
        end.to_set
      end
    end
  end
end
