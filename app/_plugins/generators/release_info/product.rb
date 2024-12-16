# frozen_string_literal: true

require_relative './releasable'

module Jekyll
  module ReleaseInfo
    class Product
      include Releasable

      def initialize(site:, product:, min_version:, max_version:)
        @site = site
        @product = product
        @min_version = min_version
        @max_version = max_version
      end

      def available_releases
        @available_releases ||= (@site.data.dig('products', @product, 'releases') || [])
                                .map { |r| Drops::Release.new(r) }
      end

      private

      def key
        @key ||= @product
      end
    end
  end
end
