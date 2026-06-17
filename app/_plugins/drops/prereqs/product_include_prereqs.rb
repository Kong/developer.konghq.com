# frozen_string_literal: true

module Jekyll
  module Drops
    class ProductIncludePrereqs
      PRODUCT_INCLUDES_PATH = 'prereqs/products/'
      PRODUCT_INCLUDES = Dir.glob("app/_includes/#{PRODUCT_INCLUDES_PATH}**/*.md").freeze

      class << self
        def product_include_paths
          @product_include_paths ||= PRODUCT_INCLUDES.map do |path|
            path.sub("app/_includes/#{PRODUCT_INCLUDES_PATH}", '').sub('.md', '')
          end.to_set
        end
      end

      def self.exist?(product_include)
        product_include_paths.include?(product_include)
      end
    end
  end
end
