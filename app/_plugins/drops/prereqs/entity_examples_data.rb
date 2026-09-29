# frozen_string_literal: true

module Jekyll
  module Drops
    class EntityExamplesData
      def initialize(product:, entities:, entity_examples:, major:, product_data:)
        @product = product
        @entities = entities
        @entity_examples = entity_examples
        @major = major
        @product_data = product_data
      end

      def to_h
        @entities.each_with_object({}) do |(k, files), hash|
          hash[k] = fetch_files(k, files)
        end
      end

      private

      def fetch_files(k, files)
        files.map do |f|
          key = versioned_key(k, f)
          example = @entity_examples.dig(*key)
          raise ArgumentError, missing_error(key) unless example

          example
        end
      end

      def versioned_key(k, f)
        return [@product, k, f] unless @major

        [@product, major_url_segment, k, f]
      end

      def missing_error(key)
        "Missing entity_example file in app/_data/entity_examples/#{key.join('/')}.{yml,yaml}"
      end

      def major_url_segment
        MajorVersionResolver.process(
          product_data: @product_data,
          major: @major
        )
      end
    end
  end
end
