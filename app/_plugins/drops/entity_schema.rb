# frozen_string_literal: true

module Jekyll
  module Drops
    class EntitySchema < Liquid::Drop
      def initialize(schema:, site:)
        @schema = schema
        @site   = site
      end

      def data
        {
          'product' => { 'id' => product_id },
          'version' => { 'id' => version_id },
          'path' => path
        }
      end

      def path
        @path ||= @schema.fetch('path')
      end

      def product_id
        @product_id ||= begin
          product_ids = @site.data.fetch('konnect_product_ids')

          product_id = product_ids.dig(*@schema.fetch('api').split('/'))

          unless product_id
            raise ArgumentError, "Missing `konnect_product_id` for #{@schema['api']} in app/_data/konnect_product_ids.yml"
          end
          product_id
        end
      end

      def version_id
        # XXX: for now, until we generate versions
        @version_id ||= product.dig('latestVersion', 'id')
      end

      private

      def product
        @product ||= @site.data['konnect_oas_data'].detect { |p| p['id'] == product_id }
      end
    end
  end
end
