# frozen_string_literal: true

module Jekyll
  module Drops
    class EntitySchema < Liquid::Drop
      def initialize(schema:, site:, release:)
        @schema  = schema
        @site    = site
        @release = release
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
          id = @site.data['konnect_product_ids']["/api/#{@schema.fetch('api')}/"]

          raise ArgumentError, "There's no API in app/_api/ that matches #{@schema.fetch('api')}" unless id

          id
        end
      end

      def version_id
        @version_id ||= if @release.label?
                          product.dig('latestVersion', 'id')
                        else
                          product
                            .fetch('versions', [])
                            .detect { |v| v['name'] == @release.to_konnect_version }
                            .fetch('id')
                        end
      end

      private

      def product
        @product ||= @site.data['konnect_oas_data'].detect { |p| p['id'] == product_id }
      end
    end
  end
end
