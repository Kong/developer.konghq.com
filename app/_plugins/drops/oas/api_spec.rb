# frozen_string_literal: true

module Jekyll
  module Drops
    module OAS
      class APISpec < Liquid::Drop
        def initialize(product:, version:)
          @product = product
          @version = version
        end

        def title
          @title ||= @product.fetch('title')
        end

        def description
          @description ||= @product.fetch('description')
        end

        def latest_version
          @latest_version ||= @product.fetch('latestVersion').fetch('name')
        end

        def deprecated?
          version = @product.fetch('versions', []).detect do |v|
            v.fetch('name') == latest_version
          end

          version&.fetch('deprecated')
        end

        def as_json
          {
            'product_id' => @product.fetch('id'),
            'version_id' => @version.fetch('id')
          }
        end
      end
    end
  end
end
