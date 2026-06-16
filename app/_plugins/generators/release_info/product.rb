# frozen_string_literal: true

require_relative './releasable'

module Jekyll
  module ReleaseInfo
    class Product
      include Releasable

      def initialize(site:, product:, min_version:, max_version:, major: nil)
        @site = site
        @product = product
        @major = major
        @min_version = min_version
        @max_version = max_version
      end

      def available_releases
        @available_releases ||= raw_releases
                                .select { |r| major_of(r['release']) == major }
                                .map { |r| Drops::Release.new(r) }
      end

      def deduplicated_releases
        return releases unless @product == 'event-gateway'

        @deduplicated_releases ||= releases.group_by { |r| r['name'] }
                                           .values
                                           .map(&:max)
      end

      def use_release_name?
        @product == 'event-gateway'
      end

      private

      def key
        @key ||= @product
      end

      def raw_releases
        @site.data.dig('products', @product, 'releases') || []
      end

      def major_of(version_string)
        version_string.to_s.split('.').first.to_i
      end

      def major
        @major ||= MajorResolver.new(
          site: @site,
          product: @product,
          page_major_version: @major_version,
          min_version: @min_version[@product],
          max_version: @max_version[@product]
        ).resolve
      end
    end
  end
end
